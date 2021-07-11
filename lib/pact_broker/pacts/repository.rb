require "sequel"
require "ostruct"
require "pact_broker/logging"
require "pact_broker/pacts/generate_sha"
require "pact_broker/pacts/pact_publication"
require "pact_broker/pacts/pact_version"
require "pact_broker/pacts/all_pact_publications"
require "pact_broker/pacts/latest_pact_publications_by_consumer_version"
require "pact_broker/pacts/latest_pact_publications"
require "pact_broker/pacts/latest_tagged_pact_publications"
require "pact/shared/json_differ"
require "pact_broker/domain"
require "pact_broker/pacts/parse"
require "pact_broker/matrix/head_row"
require "pact_broker/pacts/latest_pact_publication_id_for_consumer_version"
require "pact_broker/pacts/verifiable_pact"
require "pact_broker/repositories/helpers"
require "pact_broker/pacts/selected_pact"
require "pact_broker/pacts/selector"
require "pact_broker/pacts/selectors"
require "pact_broker/feature_toggle"
require "pact_broker/pacts/pacts_for_verification_repository"

module PactBroker
  module Pacts
    # rubocop: disable Metrics/ClassLength
    class Repository
      include PactBroker::Logging
      include PactBroker::Repositories
      include PactBroker::Repositories::Helpers

      def scope_for(scope)
        PactBroker.policy_scope!(scope)
      end

      # For the times when it doesn't make sense to use the scoped class, this is a way to
      # indicate that it is an intentional use of the PactVersion class directly.
      def unscoped(scope)
        scope
      end

      def create params
        pact_version = find_or_create_pact_version(
          params.fetch(:consumer_id),
          params.fetch(:provider_id),
          params.fetch(:pact_version_sha),
          params.fetch(:json_content)
        )
        pact_publication = PactPublication.new(
          consumer_version_id: params[:version_id],
          provider_id: params[:provider_id],
          consumer_id: params[:consumer_id],
          pact_version: pact_version,
          revision_number: 1,
          consumer_version_order: params.fetch(:version).order,
        ).upsert
        update_latest_pact_publication_ids(pact_publication)
        pact_publication.to_domain
      end

      def update id, params
        existing_model = PactPublication.find(id: id)
        pact_version = find_or_create_pact_version(
          existing_model.consumer_version.pacticipant_id,
          existing_model.provider_id,
          params.fetch(:pact_version_sha),
          params.fetch(:json_content)
        )
        if existing_model.pact_version_id != pact_version.id
          pact_publication = PactPublication.new(
            consumer_version_id: existing_model.consumer_version_id,
            provider_id: existing_model.provider_id,
            revision_number: next_revision_number(existing_model),
            consumer_id: existing_model.consumer_id,
            consumer_version_order: existing_model.consumer_version_order,
            pact_version_id: pact_version.id,
            created_at: Sequel.datetime_class.now
          ).upsert
          update_latest_pact_publication_ids(pact_publication)
          pact_publication.to_domain
        else
          existing_model.to_domain
        end
      end

      # This logic is a separate method so we can stub it to create a "conflict" scenario
      def next_revision_number(existing_model)
        existing_model.revision_number + 1
      end

      def update_latest_pact_publication_ids(pact_publication)
        params = {
          consumer_version_id: pact_publication.consumer_version_id,
          provider_id: pact_publication.provider_id,
          pact_publication_id: pact_publication.id,
          consumer_id: pact_publication.consumer_id,
          pact_version_id: pact_publication.pact_version_id,
          created_at: pact_publication.consumer_version.created_at
        }

        LatestPactPublicationIdForConsumerVersion.new(params).upsert
      end

      def delete params
        id = scope_for(PactPublication)
          .join_consumers
          .join_providers
          .join_consumer_versions
          .consumer_name_like(params.consumer_name)
          .provider_name_like(params.provider_name)
          .consumer_version_number_like(params.consumer_version_number)
          .select_for_subquery(Sequel[:pact_publications][:id].as(:id))
        unscoped(PactPublication).where(id: id).delete
      end

      def delete_by_version_id version_id
        scope_for(PactPublication).where(consumer_version_id: version_id).delete
      end

      def find_all_pact_versions_between consumer_name, options
        find_all_database_versions_between(consumer_name, options)
          .eager(:tags)
          .reverse_order(:consumer_version_order)
          .collect(&:to_domain)
      end

      def delete_all_pact_publications_between consumer_name, options
        consumer = pacticipant_repository.find_by_name!(consumer_name)
        provider = pacticipant_repository.find_by_name!(options.fetch(:and))
        query = scope_for(PactPublication).where(consumer: consumer, provider: provider)
        query = query.tag(options[:tag]) if options[:tag]

        ids = query.select_for_subquery(:id)
        webhook_repository.delete_triggered_webhooks_by_pact_publication_ids(ids)
        unscoped(PactPublication).where(id: ids).delete
      end

      def delete_all_pact_versions_between consumer_name, options
        consumer = pacticipant_repository.find_by_name(consumer_name)
        provider = pacticipant_repository.find_by_name(options.fetch(:and))
        scope_for(PactVersion).where(consumer: consumer, provider: provider).delete
      end

      def find_latest_pacts_for_provider provider_name, tag = nil
        query = scope_for(PactPublication)
                  .for_provider_name(provider_name)
                  .eager(:consumer)

        if tag
          query = query.latest_for_consumer_tag(tag)
        else
          query = query.overall_latest
        end

        query.sort_by{ | p| p.consumer_name.downcase }.collect(&:to_head_pact)
      end

      def find_for_verification(provider_name, consumer_version_selectors)
        PactsForVerificationRepository.new.find(provider_name, consumer_version_selectors)
      end

      def find_wip_pact_versions_for_provider provider_name, provider_version_branch, provider_tags_names = [], options = {}
        PactsForVerificationRepository.new.find_wip(provider_name, provider_version_branch, provider_tags_names, options)
      end

      def find_pact_versions_for_provider provider_name, tag = nil
        if tag
          scope_for(LatestPactPublicationsByConsumerVersion)
            .join(:tags, {version_id: :consumer_version_id})
            .provider(provider_name)
            .order_ignore_case(:consumer_name)
            .order_append(:consumer_version_order)
            .where(Sequel[:tags][:name] => tag)
            .collect(&:to_domain)
        else
          scope_for(LatestPactPublicationsByConsumerVersion)
            .provider(provider_name)
            .order_ignore_case(:consumer_name)
            .order_append(:consumer_version_order)
            .collect(&:to_domain)
        end
      end

      # Returns latest pact version for the consumer_version_number
      def find_by_consumer_version consumer_name, consumer_version_number
        scope_for(LatestPactPublicationsByConsumerVersion)
          .consumer(consumer_name)
          .consumer_version_number(consumer_version_number)
          .collect(&:to_domain_with_content)
      end

      def find_by_version_and_provider version_id, provider_id
        scope_for(LatestPactPublicationsByConsumerVersion)
          .eager(:tags)
          .where(consumer_version_id: version_id, provider_id: provider_id)
          .limit(1).collect(&:to_domain_with_content)[0]
      end

      def find_latest_pacts
        scope_for(PactPublication)
          .overall_latest
          .eager(:consumer)
          .eager(:provider)
          .collect(&:to_domain)
          .sort
      end

      def find_latest_pact(consumer_name, provider_name, tag = nil)
        query = scope_for(LatestPactPublicationsByConsumerVersion)
          .select_all_qualified
          .consumer(consumer_name)
          .provider(provider_name)
        if tag == :untagged
          query = query.untagged
        elsif tag
          query = query.tag(tag)
        end
        query.latest.all.collect(&:to_domain_with_content)[0]
      end

      # Allows optional consumer_name and provider_name
      def search_for_latest_pact(consumer_name, provider_name, tag = nil)
        query = scope_for(LatestPactPublicationsByConsumerVersion).select_all_qualified
        query = query.consumer(consumer_name) if consumer_name
        query = query.provider(provider_name) if provider_name

        if tag == :untagged
          query = query.untagged
        elsif tag
          query = query.tag(tag)
        end
        query.latest.all.collect(&:to_domain_with_content)[0]
      end

      # rubocop: disable Metrics/CyclomaticComplexity, Metrics/MethodLength
      def find_pact consumer_name, consumer_version_number, provider_name, pact_version_sha = nil
        pact_publication_by_consumer_version = scope_for(PactPublication)
            .select_all_qualified
            .for_consumer_name_and_maybe_version_number(consumer_name, consumer_version_number)
            .for_provider_name(provider_name)
            .remove_overridden_revisions
            .limit(1)

        latest_pact_publication_by_sha = scope_for(PactPublication)
            .select_all_qualified
            .for_consumer_name(consumer_name)
            .for_provider_name(provider_name)
            .for_pact_version_sha(pact_version_sha)
            .reverse_order(:consumer_version_order, :revision_number)
            .limit(1)

        if consumer_version_number && !pact_version_sha
          pact_publication_by_consumer_version
            .eager(:tags)
            .collect(&:to_domain_with_content).first
        elsif pact_version_sha && !consumer_version_number
          latest_pact_publication_by_sha
            .eager(:tags)
            .collect(&:to_domain_with_content).first
        elsif consumer_version_number && pact_version_sha
          pact_publication = pact_publication_by_consumer_version.all.first
          if pact_publication && pact_publication.pact_version.sha == pact_version_sha
            pact_publication.tags
            pact_publication.to_domain_with_content
          else
            latest_pact_publication_by_sha
              .eager(:tags)
              .collect(&:to_domain_with_content).first
          end
        else
          pact_publication_by_consumer_version
            .eager(:tags)
            .reverse_order(:consumer_version_order, :revision_number)
            .collect(&:to_domain_with_content).first
        end
      end
      # rubocop: enable Metrics/CyclomaticComplexity, Metrics/MethodLength

      def find_all_revisions consumer_name, consumer_version_number, provider_name
        scope_for(PactPublication)
          .for_provider_name(provider_name)
          .for_consumer_name_and_maybe_version_number(consumer_name, consumer_version_number)
          .order_by_consumer_version_order
          .collect(&:to_domain_with_content)
      end

      def find_previous_pact pact, tag = nil
        query = scope_for(LatestPactPublicationsByConsumerVersion)
            .eager(:tags)
            .consumer(pact.consumer.name)
            .provider(pact.provider.name)

        if tag == :untagged
          query = query.untagged
        elsif tag
          query = query.tag(tag)
        end

        query.consumer_version_order_before(pact.consumer_version.order)
            .latest.collect(&:to_domain_with_content)[0]
      end

      def find_next_pact pact
        scope_for(LatestPactPublicationsByConsumerVersion)
          .eager(:tags)
          .consumer(pact.consumer.name)
          .provider(pact.provider.name)
          .consumer_version_order_after(pact.consumer_version.order)
          .earliest.collect(&:to_domain_with_content)[0]
      end

      def find_previous_distinct_pact pact
        previous, current = nil, pact
        loop do
          previous = find_previous_distinct_pact_by_sha current
          return previous if previous.nil? || different?(current, previous)
          current = previous
        end
      end

      def find_previous_pacts pact
        if pact.consumer_version_tag_names.any?
          pact.consumer_version_tag_names.each_with_object({}) do |tag, tags_to_pacts|
            tags_to_pacts[tag] = find_previous_pact(pact, tag)
          end
        else
          { :untagged => find_previous_pact(pact, :untagged) }
        end
      end

      private

      def find_previous_distinct_pact_by_sha pact
        current_pact_content_sha =
          scope_for(LatestPactPublicationsByConsumerVersion).select(:pact_version_sha)
          .consumer(pact.consumer.name)
          .provider(pact.provider.name)
          .consumer_version_number(pact.consumer_version_number)
          .limit(1)

        scope_for(LatestPactPublicationsByConsumerVersion)
          .eager(:tags)
          .consumer(pact.consumer.name)
          .provider(pact.provider.name)
          .consumer_version_order_before(pact.consumer_version.order)
          .where(Sequel.lit("pact_version_sha != ?", current_pact_content_sha))
          .latest
          .collect(&:to_domain_with_content)[0]
      end

      def different? pact, other_pact
        Pact::JsonDiffer.(pact.content_hash, other_pact.content_hash, allow_unexpected_keys: false).any?
      end

      def find_or_create_pact_version consumer_id, provider_id, pact_version_sha, json_content
        unscoped(PactVersion).find(sha: pact_version_sha, consumer_id: consumer_id, provider_id: provider_id) ||
          create_pact_version(consumer_id, provider_id, pact_version_sha, json_content)
      end

      def create_pact_version consumer_id, provider_id, sha, json_content
        PactBroker::Pacts::PactVersion.new(
          consumer_id: consumer_id,
          provider_id: provider_id,
          sha: sha,
          content: json_content,
          created_at: Sequel.datetime_class.now
        ).upsert
      end

      def find_all_database_versions_between(consumer_name, options, base_class = LatestPactPublicationsByConsumerVersion)
        provider_name = options.fetch(:and)

        query = scope_for(base_class)
          .consumer(consumer_name)
          .provider(provider_name)

        query = query.tag(options[:tag]) if options[:tag]
        query
      end

      # Note: created_at is coming back as a string for sqlite
      # Can't work out how to to tell Sequel that this should be a date
      def to_datetime string_or_datetime
        if string_or_datetime.is_a?(String)
          Sequel.string_to_datetime(string_or_datetime)
        else
          string_or_datetime
        end
      end
    end
    # rubocop: enable Metrics/ClassLength
  end
end
