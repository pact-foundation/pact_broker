require 'sequel'
require 'ostruct'
require 'pact_broker/logging'
require 'pact_broker/pacts/generate_sha'
require 'pact_broker/pacts/pact_publication'
require 'pact_broker/pacts/all_pact_publications'
require 'pact_broker/pacts/latest_pact_publications_by_consumer_version'
require 'pact_broker/pacts/latest_pact_publications'
require 'pact_broker/pacts/latest_tagged_pact_publications'
require 'pact/shared/json_differ'
require 'pact_broker/domain'
require 'pact_broker/pacts/parse'
require 'pact_broker/matrix/head_row'
require 'pact_broker/pacts/latest_pact_publication_id_by_consumer_version'

module PactBroker
  module Pacts
    class Repository

      include PactBroker::Logging
      include PactBroker::Repositories

      def create params
        pact_publication = PactPublication.new(
          consumer_version_id: params[:version_id],
          provider_id: params[:provider_id],
          consumer_id: params[:consumer_id],
          pact_version: find_or_create_pact_version(params.fetch(:consumer_id), params.fetch(:provider_id), params[:json_content]),
        ).save
        update_latest_pact_publication_ids(pact_publication)
        pact_publication.to_domain
      end

      def update id, params
        existing_model = PactPublication.find(id: id)
        pact_version = find_or_create_pact_version(existing_model.consumer_version.pacticipant_id, existing_model.provider_id, params[:json_content])
        if existing_model.pact_version_id != pact_version.id
          pact_publication = PactPublication.new(
            consumer_version_id: existing_model.consumer_version_id,
            consumer_id: existing_model.consumer_id,
            provider_id: existing_model.provider_id,
            revision_number: (existing_model.revision_number + 1),
            pact_version: pact_version,
          ).save
          update_latest_pact_publication_ids(pact_publication)
          pact_publication.to_domain
        else
          existing_model.to_domain
        end
      end

      def update_latest_pact_publication_ids(pact_publication)
        params = {
          consumer_version_id: pact_publication.consumer_version_id,
          provider_id: pact_publication.provider_id,
          pact_publication_id: pact_publication.id,
          consumer_id: pact_publication.consumer_id,
          pact_version_id: pact_publication.pact_version_id
        }

        LatestPactPublicationIdForConsumerVersion.new(params).upsert
      end

      def delete params
        id = AllPactPublications
          .consumer(params.consumer_name)
          .provider(params.provider_name)
          .consumer_version_number(params.consumer_version_number)
          .select_for_subquery(:id)
        PactPublication.where(id: id).delete
      end

      def delete_by_version_id version_id
        Sequel::Model.db[:pact_publications].where(consumer_version_id: version_id).delete
      end

      def find_all_pact_versions_between consumer_name, options
        provider_name = options.fetch(:and)
        LatestPactPublicationsByConsumerVersion
          .eager(:tags)
          .consumer(consumer_name)
          .provider(provider_name)
          .reverse_order(:consumer_version_order)
          .collect(&:to_domain)
      end

      def find_latest_pact_versions_for_provider provider_name, tag = nil
        if tag
          LatestTaggedPactPublications.provider(provider_name).order_ignore_case(:consumer_name).where(tag_name: tag).collect(&:to_domain)
        else
          LatestPactPublications.provider(provider_name).order_ignore_case(:consumer_name).collect(&:to_domain)
        end
      end

      def find_wip_pact_versions_for_provider provider_name
        provider_id = pacticipant_repository.find_by_name(provider_name).id
        pact_publication_ids = PactBroker::Matrix::HeadRow.where(provider_id: provider_id).exclude(success: true).select_for_subquery(:pact_publication_id)
        AllPactPublications.where(id: pact_publication_ids).order_ignore_case(:consumer_name).order_append(:consumer_version_order).collect(&:to_domain)
      end

      def find_pact_versions_for_provider provider_name, tag = nil
        if tag
          LatestPactPublicationsByConsumerVersion
            .join(:tags, {version_id: :consumer_version_id})
            .provider(provider_name)
            .order_ignore_case(:consumer_name)
            .order_append(:consumer_version_order)
            .where(Sequel[:tags][:name] => tag)
            .collect(&:to_domain)
        else
          LatestPactPublicationsByConsumerVersion
            .provider(provider_name)
            .order_ignore_case(:consumer_name)
            .order_append(:consumer_version_order)
            .collect(&:to_domain)
        end
      end

      # Returns latest pact version for the consumer_version_number
      def find_by_consumer_version consumer_name, consumer_version_number
        LatestPactPublicationsByConsumerVersion
          .consumer(consumer_name)
          .consumer_version_number(consumer_version_number)
          .collect(&:to_domain_with_content)
      end

      def find_by_version_and_provider version_id, provider_id
        LatestPactPublicationsByConsumerVersion
          .eager(:tags)
          .where(consumer_version_id: version_id, provider_id: provider_id)
          .limit(1).collect(&:to_domain_with_content)[0]
      end

      def find_latest_pacts
        LatestPactPublications.order(:consumer_name, :provider_name).collect(&:to_domain)
      end

      def find_latest_pact(consumer_name, provider_name, tag = nil)
        query = LatestPactPublicationsByConsumerVersion
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
        query = LatestPactPublicationsByConsumerVersion.select_all_qualified
        query = query.consumer(consumer_name) if consumer_name
        query = query.provider(provider_name) if provider_name

        if tag == :untagged
          query = query.untagged
        elsif tag
          query = query.tag(tag)
        end
        query.latest.all.collect(&:to_domain_with_content)[0]
      end

      def find_pact consumer_name, consumer_version, provider_name, pact_version_sha = nil
        query = if pact_version_sha
          AllPactPublications
            .pact_version_sha(pact_version_sha)
            .reverse_order(:consumer_version_order)
            .limit(1)
        else
          LatestPactPublicationsByConsumerVersion
        end
        query = query
          .eager(:tags)
          .consumer(consumer_name)
          .provider(provider_name)
        query = query.consumer_version_number(consumer_version) if consumer_version
        query.collect(&:to_domain_with_content)[0]
      end

      def find_all_revisions consumer_name, consumer_version, provider_name
        AllPactPublications
          .consumer(consumer_name)
          .provider(provider_name)
          .consumer_version_number(consumer_version)
          .order(:consumer_version_order, :revision_number).collect(&:to_domain_with_content)
      end

      def find_previous_pact pact
        LatestPactPublicationsByConsumerVersion
          .eager(:tags)
          .consumer(pact.consumer.name)
          .provider(pact.provider.name)
          .consumer_version_order_before(pact.consumer_version.order)
          .latest.collect(&:to_domain_with_content)[0]
      end

      def find_next_pact pact
        LatestPactPublicationsByConsumerVersion
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

      private

      def find_previous_distinct_pact_by_sha pact
        current_pact_content_sha =
          LatestPactPublicationsByConsumerVersion.select(:pact_version_sha)
          .consumer(pact.consumer.name)
          .provider(pact.provider.name)
          .consumer_version_number(pact.consumer_version_number)
          .limit(1)

        LatestPactPublicationsByConsumerVersion
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

      def find_or_create_pact_version consumer_id, provider_id, json_content
        sha = PactBroker.configuration.sha_generator.call(json_content)
        PactVersion.find(sha: sha, consumer_id: consumer_id, provider_id: provider_id) || create_pact_version(consumer_id, provider_id, sha, json_content)
      end

      def create_pact_version consumer_id, provider_id, sha, json_content
        logger.debug("Creating new pact version for sha #{sha}")
        pact_version = PactVersion.new(consumer_id: consumer_id, provider_id: provider_id, sha: sha, content: json_content)
        pact_version.save
      end
    end
  end
end
