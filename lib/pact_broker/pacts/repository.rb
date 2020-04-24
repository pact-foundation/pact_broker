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
require 'pact_broker/pacts/latest_pact_publication_id_for_consumer_version'
require 'pact_broker/pacts/verifiable_pact'
require 'pact_broker/repositories/helpers'
require 'pact_broker/pacts/selected_pact'
require 'pact_broker/pacts/selector'
require 'pact_broker/pacts/selectors'

module PactBroker
  module Pacts
    class Repository

      include PactBroker::Logging
      include PactBroker::Repositories
      include PactBroker::Repositories::Helpers

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
          revision_number: 1
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
        find_all_database_versions_between(consumer_name, options)
          .eager(:tags)
          .reverse_order(:consumer_version_order)
          .collect(&:to_domain)
      end

      def delete_all_pact_publications_between consumer_name, options
        consumer = pacticipant_repository.find_by_name(consumer_name)
        provider = pacticipant_repository.find_by_name(options.fetch(:and))
        query = PactPublication.where(consumer: consumer, provider: provider)
        query = query.tag(options[:tag]) if options[:tag]

        ids = query.select_for_subquery(:id)
        webhook_repository.delete_triggered_webhooks_by_pact_publication_ids(ids)
        PactPublication.where(id: ids).delete
      end

      def delete_all_pact_versions_between consumer_name, options
        consumer = pacticipant_repository.find_by_name(consumer_name)
        provider = pacticipant_repository.find_by_name(options.fetch(:and))
        PactVersion.where(consumer: consumer, provider: provider).delete
      end

      def find_latest_pact_versions_for_provider provider_name, tag = nil
        if tag
          LatestTaggedPactPublications.provider(provider_name).order_ignore_case(:consumer_name).where(tag_name: tag).collect(&:to_domain)
        else
          LatestPactPublications.provider(provider_name).order_ignore_case(:consumer_name).collect(&:to_domain)
        end
      end

      def find_all_pact_versions_for_provider_with_consumer_version_tags provider_name, selector
        provider = pacticipant_repository.find_by_name(provider_name)
        consumer = selector.consumer ? pacticipant_repository.find_by_name(selector.consumer) : nil

        PactPublication
          .select_all_qualified
          .select_append(Sequel[:cv][:order].as(:consumer_version_order))
          .select_append(Sequel[:ct][:name].as(:consumer_version_tag_name))
          .remove_overridden_revisions
          .join_consumer_versions(:cv)
          .join_consumer_version_tags_with_names(selector.tag)
          .where(provider: provider)
          .where_consumer_if_set(consumer)
          .eager(:consumer)
          .eager(:consumer_version)
          .eager(:provider)
          .eager(:pact_version)
          .all
          .group_by(&:pact_version_id)
          .values
          .collect do | pact_publications |
            latest_pact_publication = pact_publications.sort_by{ |p| p.values.fetch(:consumer_version_order) }.last
            SelectedPact.new(latest_pact_publication.to_domain, Selectors.new(selector))
          end
      end

      # To find the work in progress pacts for this verification execution:
      # For each provider tag that will be applied to this verification result (usually there will just be one, but
      # we have to allow for multiple tags),
      # find the head pacts (the pacts that are the latest for their tag) that have been successfully
      # verified against the provider tag.
      # Then, find all the head pacts, and remove the ones that have been successfully verified by ALL
      # of the provider tags supplied, and the ones that were published before the include_wip_pacts_since date.
      # Then, for all of the head pacts that are remaining (these are the WIP ones) work out which
      # provider tags they are pending for.
      # Don't include pact publications that were created before the provider tag was first used
      # (that is, before the provider's git branch was created).
      def find_wip_pact_versions_for_provider provider_name, provider_tags_names = [], options = {}
        # TODO not sure about this
        return [] if provider_tags_names.empty?

        provider = pacticipant_repository.find_by_name(provider_name)

        # Hash of provider tag name => list of head pacts that have been successfully verified by that tag
        successfully_verified_head_pacts_for_provider_tags = find_successfully_verified_head_pacts_by_provider_tag(provider.id, provider_tags_names, options)
        # Create hash of provider tag name => list of pact publication ids
        successfully_verified_head_pact_publication_ids_for_each_provider_tag = successfully_verified_head_pacts_for_provider_tags.each_with_object({}) do | (provider_tag_name, head_pacts), hash |
          hash[provider_tag_name] = head_pacts.collect(&:id).uniq
        end

        # list of head pact_publication_ids that are NOT work in progress because they've been verified by all of the provider version tags supplied
        non_wip_pact_publication_ids = successfully_verified_head_pacts_for_provider_tags.values.collect{ |head_pacts| head_pacts.collect(&:id) }.reduce(:&)

        wip_pact_publication_ids = find_head_pacts_that_have_not_been_successfully_verified_by_all_provider_tags(
          provider.id,
          non_wip_pact_publication_ids,
          options)

        wip_pacts = AllPactPublications.where(id: wip_pact_publication_ids).order_ignore_case(:consumer_name).order_append(:consumer_version_order)

        # The first instance (by date) of each provider tag with that name
        provider_tag_collection = PactBroker::Domain::Tag
          .select_group(Sequel[:tags][:name], Sequel[:pacticipant_id])
          .select_append(Sequel.function(:min, Sequel[:tags][:created_at]).as(:created_at))
          .distinct
          .join(:versions, { Sequel[:tags][:version_id] => Sequel[:versions][:id] } )
          .where(pacticipant_id: provider.id)
          .where(name: provider_tags_names)
          .all

        wip_pacts.collect do | pact|

          pending_tag_names = find_provider_tags_for_which_pact_publication_id_is_pending(pact, successfully_verified_head_pact_publication_ids_for_each_provider_tag)
          pre_existing_tag_names = find_provider_tag_names_that_were_first_used_before_pact_published(pact, provider_tag_collection)

          pre_existing_pending_tags = pending_tag_names & pre_existing_tag_names

          if pre_existing_pending_tags.any?
            selectors = Selectors.create_for_latest_of_each_tag(pact.head_tag_names)
            VerifiablePact.new(pact.to_domain, selectors, true, pre_existing_pending_tags, [], true)
          end
        end.compact
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

      def find_previous_pact pact, tag = nil
        query = LatestPactPublicationsByConsumerVersion
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

      def find_previous_pacts pact
        if pact.consumer_version_tag_names.any?
          pact.consumer_version_tag_names.each_with_object({}) do |tag, tags_to_pacts|
            tags_to_pacts[tag] = find_previous_pact(pact, tag)
          end
        else
          { :untagged => find_previous_pact(pact, :untagged) }
        end
      end

      # Returns a list of Domain::Pact objects the represent pact publications
      def find_for_verification(provider_name, consumer_version_selectors)
        selected_pacts = find_pacts_for_which_the_latest_version_is_required(provider_name, consumer_version_selectors) +
        find_pacts_for_which_the_latest_version_for_the_tag_is_required(provider_name, consumer_version_selectors) +
        find_pacts_for_which_all_versions_for_the_tag_are_required(provider_name, consumer_version_selectors)

        selected_pacts = selected_pacts + find_pacts_for_fallback_tags(selected_pacts, provider_name, consumer_version_selectors)

        selected_pacts
          .group_by(&:pact_version_sha)
          .values
          .collect do | selected_pacts_for_pact_version_id |
            SelectedPact.merge(selected_pacts_for_pact_version_id)
          end

      end

      private

      def find_pacts_for_fallback_tags(selected_pacts, provider_name, consumer_version_selectors)
        # TODO at the moment, the validation doesn't stop fallback being used with 'all' selectors
        selectors_with_fallback_tags = consumer_version_selectors.select(&:fallback_tag?)
        selectors_missing_a_pact = selectors_with_fallback_tags.reject do | selector |
          selected_pacts.any? do | selected_pact |
            selected_pact.latest_for_tag?(selector.tag)
          end
        end

        if selectors_missing_a_pact.any?
          find_pacts_for_which_the_latest_version_for_the_fallback_tag_is_required(provider_name, selectors_missing_a_pact)
        else
          []
        end
      end

      def find_pacts_for_which_the_latest_version_is_required(provider_name, consumer_version_selectors)
        if consumer_version_selectors.empty?
          LatestPactPublications
            .provider(provider_name)
            .order_ignore_case(:consumer_name)
            .collect do | latest_pact_publication |
              pact_publication = PactPublication.find(id: latest_pact_publication.id)
              SelectedPact.new(pact_publication.to_domain, Selectors.create_for_overall_latest)
            end
        else
          []
        end
      end

      def find_pacts_for_which_the_latest_version_for_the_tag_is_required(provider_name, consumer_version_selectors)
        # The tags for which only the latest version is specified
        tag_names = consumer_version_selectors.tag_names_of_selectors_for_latest_pacts

        # TODO make this an efficient query!
        # These are not yet de-duped. Should make the behaviour consistent between this and find_pacts_for_which_all_versions_for_the_tag_are_required ?
        if tag_names.any?
          LatestTaggedPactPublications
            .provider(provider_name)
            .where(tag_name: tag_names)
            .all
            .group_by(&:pact_version_id)
            .values
            .collect do | pact_publications |
              create_selected_pact(pact_publications)
            end
        else
          []
        end
      end

      def create_selected_pact(pact_publications)
        selector_tag_names = pact_publications.collect(&:tag_name)
        selectors = Selectors.create_for_latest_of_each_tag(selector_tag_names)
        last_pact_publication = pact_publications.sort_by(&:consumer_version_order).last
        pact_publication = PactPublication.find(id: last_pact_publication.id)
        SelectedPact.new(
          pact_publication.to_domain,
          selectors
        )
      end

      def create_fallback_selected_pact(pact_publications, consumer_version_selectors)
        selector_tag_names = pact_publications.collect(&:tag_name)
        selectors = Selectors.create_for_latest_fallback_of_each_tag(selector_tag_names)
        last_pact_publication = pact_publications.sort_by(&:consumer_version_order).last
        pact_publication = PactPublication.find(id: last_pact_publication.id)
        SelectedPact.new(
          pact_publication.to_domain,
          selectors
        )
      end

      def find_pacts_for_which_the_latest_version_for_the_fallback_tag_is_required(provider_name, selectors)
        selectors.collect do | selector |
          LatestTaggedPactPublications
            .provider(provider_name)
            .where(tag_name: selector.fallback_tag)
            .all
            .collect do | latest_tagged_pact_publication |
              pact_publication = PactPublication.find(id: latest_tagged_pact_publication.id)
              SelectedPact.new(
                pact_publication.to_domain,
                Selectors.new(selector)
              )
            end
        end.flatten
      end


      def find_pacts_for_which_all_versions_for_the_tag_are_required(provider_name, consumer_version_selectors)
        # The tags for which all versions are specified
        selectors = consumer_version_selectors.select(&:all_for_tag?)

        selectors.flat_map do | selector |
          find_all_pact_versions_for_provider_with_consumer_version_tags(provider_name, selector)
        end
      end

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

      def find_or_create_pact_version consumer_id, provider_id, pact_version_sha, json_content
        PactVersion.find(sha: pact_version_sha, consumer_id: consumer_id, provider_id: provider_id) || create_pact_version(consumer_id, provider_id, pact_version_sha, json_content)
      end

      def create_pact_version consumer_id, provider_id, sha, json_content
        PactVersion.new(
          consumer_id: consumer_id,
          provider_id: provider_id,
          sha: sha,
          content: json_content,
          created_at: Sequel.datetime_class.now
        ).upsert
      end

      def find_all_database_versions_between(consumer_name, options, base_class = LatestPactPublicationsByConsumerVersion)
        provider_name = options.fetch(:and)

        query = base_class
          .consumer(consumer_name)
          .provider(provider_name)

        query = query.tag(options[:tag]) if options[:tag]
        query
      end

      def find_provider_tags_for_which_pact_publication_id_is_pending(pact_publication, successfully_verified_head_pact_publication_ids_for_each_provider_tag)
        successfully_verified_head_pact_publication_ids_for_each_provider_tag
          .select do | _, pact_publication_ids |
            !pact_publication_ids.include?(pact_publication.id)
          end.keys
      end

      def find_provider_tag_names_that_were_first_used_before_pact_published(pact_publication, provider_tag_collection)
        provider_tag_collection.select { | tag| to_datetime(tag.created_at) < pact_publication.created_at }.collect(&:name)
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

      def find_head_pacts_that_have_not_been_successfully_verified_by_all_provider_tags(provider_id, pact_publication_ids_successfully_verified_by_all_provider_tags, options)
        # Exclude the head pacts that have been successfully verified by all the specified provider tags
        LatestTaggedPactPublications
          .where(provider_id: provider_id)
          .where(Sequel.lit('latest_tagged_pact_publications.created_at > ?', options.fetch(:include_wip_pacts_since)))
          .exclude(id: pact_publication_ids_successfully_verified_by_all_provider_tags)
          .select_for_subquery(:id)
      end

      # Find the head pacts that have been successfully verified by a provider version with the specified
      # provider version tags.
      # Returns a Hash of provider_tag => LatestTaggedPactPublications with only pact publication id and tag_name populated
      # This is the list of pacts we are EXCLUDING from the WIP list because they have already been verified successfully
      def find_successfully_verified_head_pacts_by_provider_tag(provider_id, provider_tags, options)
        provider_tags.compact.each_with_object({}) do | provider_tag, hash |
          verifications_join = {
            pact_version_id: :pact_version_id,
            Sequel[:verifications][:success] => true,
            Sequel[:verifications][:provider_id] => provider_id
          }
          tags_join = {
            Sequel[:verifications][:provider_version_id] => Sequel[:provider_tags][:version_id],
            Sequel[:provider_tags][:name] => provider_tag
          }
          head_pacts = LatestTaggedPactPublications
            .select(Sequel[:latest_tagged_pact_publications][:id].as(:id))
            .join(:verifications, verifications_join)
            .join(:tags, tags_join, { table_alias: :provider_tags } )
            .where(Sequel[:latest_tagged_pact_publications][:provider_id] => provider_id)
            .distinct
            .all
          hash[provider_tag] = head_pacts
        end
      end
    end
  end
end
