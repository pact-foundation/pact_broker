require 'sequel'
require 'pact_broker/logging'
require 'pact_broker/pacts/pact_publication'
require 'pact_broker/domain'
require 'pact_broker/pacts/verifiable_pact'
require 'pact_broker/repositories/helpers'
require 'pact_broker/pacts/selected_pact'
require 'pact_broker/pacts/selector'
require 'pact_broker/pacts/selectors'
require 'pact_broker/feature_toggle'

module PactBroker
  module Pacts
    class PactsForVerificationRepository
      include PactBroker::Logging
      include PactBroker::Repositories
      include PactBroker::Repositories::Helpers

      def find(provider_name, consumer_version_selectors)
        selected_pacts = find_pacts_for_which_the_latest_version_of_something_is_required(provider_name, consumer_version_selectors) +
          find_pacts_for_which_all_versions_for_the_tag_are_required(provider_name, consumer_version_selectors)
        selected_pacts = selected_pacts + find_pacts_for_fallback_tags(selected_pacts, provider_name, consumer_version_selectors)
        merge_selected_pacts(selected_pacts)
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
      def find_wip provider_name, provider_version_branch, provider_tags_names = [], options = {}
        # TODO not sure about this
        return [] if provider_tags_names.empty? && provider_version_branch == nil

        if provider_version_branch
          return find_wip_pact_versions_for_provider_by_provider_branch(provider_name, provider_version_branch, options)
        end

        provider = pacticipant_repository.find_by_name(provider_name)
        wip_start_date = options.fetch(:include_wip_pacts_since)
        provider_tags = provider_tag_objects_for(provider, provider_tags_names)

        wip_by_consumer_tags = find_wip_pact_versions_for_provider_by_provider_tags(
          provider,
          provider_tags_names,
          provider_tags,
          wip_start_date,
          :latest_by_consumer_tag)

        wip_by_consumer_branches = find_wip_pact_versions_for_provider_by_provider_tags(
          provider,
          provider_tags_names,
          provider_tags,
          wip_start_date,
          :latest_by_consumer_branch)

        deduplicate_verifiable_pacts(wip_by_consumer_tags + wip_by_consumer_branches).sort
      end

      private

      def scope_for(scope)
        PactBroker.policy_scope!(scope)
      end

      # For the times when it doesn't make sense to use the scoped class, this is a way to
      # indicate that it is an intentional use of the PactVersion class directly.
      def unscoped(scope)
        scope
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

      def find_pacts_for_which_the_latest_version_of_something_is_required(provider_name, consumer_version_selectors)
        provider = pacticipant_repository.find_by_name(provider_name)

        selectors = if consumer_version_selectors.empty?
          Selectors.create_for_overall_latest
        else
          consumer_version_selectors.select(&:latest_for_tag?) +
            consumer_version_selectors.select(&:latest_for_branch?) +
            consumer_version_selectors.select(&:overall_latest?)
        end

        selectors.flat_map do | selector |
          query = scope_for(PactPublication).for_provider_and_consumer_version_selector(provider, selector)
          query.all.collect do | pact_publication |
            SelectedPact.new(
              pact_publication.to_domain,
              Selectors.new(selector.resolve(pact_publication.consumer_version))
            )
          end
        end
      end

      def find_pacts_for_which_the_latest_version_for_the_fallback_tag_is_required(provider_name, selectors)
        selectors.collect do | selector |
          query = scope_for(LatestTaggedPactPublications).provider(provider_name).where(tag_name: selector.fallback_tag)
          query = query.consumer(selector.consumer) if selector.consumer
          query.all
            .collect do | latest_tagged_pact_publication |
              pact_publication = unscoped(PactPublication).find(id: latest_tagged_pact_publication.id)
              SelectedPact.new(
                pact_publication.to_domain,
                Selectors.new(selector.resolve_for_fallback(pact_publication.consumer_version))
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

      def find_provider_tags_for_which_pact_publication_id_is_pending(pact_publication, successfully_verified_head_pact_publication_ids_for_each_provider_tag)
        successfully_verified_head_pact_publication_ids_for_each_provider_tag
          .select do | _, pact_publication_ids |
            !pact_publication_ids.include?(pact_publication.id)
          end.keys
      end

      def find_provider_tag_names_that_were_first_used_before_pact_published(pact_publication, provider_tag_collection)
        provider_tag_collection.select { | tag| to_datetime(tag.created_at) < pact_publication.created_at }.collect(&:name)
      end

      def deduplicate_verifiable_pacts(verifiable_pacts)
        VerifiablePact.deduplicate(verifiable_pacts)
      end

      def merge_selected_pacts(selected_pacts)
        selected_pacts
          .group_by{ |p| [p.consumer_name, p.pact_version_sha] }
          .values
          .collect do | selected_pacts_for_pact_version_id |
            SelectedPact.merge(selected_pacts_for_pact_version_id)
          end
      end

      def provider_tag_objects_for(provider, provider_tags_names)
        PactBroker::Domain::Tag
          .select_group(Sequel[:tags][:name], Sequel[:pacticipant_id])
          .select_append(Sequel.function(:min, Sequel[:tags][:created_at]).as(:created_at))
          .distinct
          .join(:versions, { Sequel[:tags][:version_id] => Sequel[:versions][:id] } )
          .where(pacticipant_id: provider.id)
          .where(name: provider_tags_names)
          .all
      end

      def find_wip_pact_versions_for_provider_by_provider_tags(provider, provider_tags_names, provider_tags, wip_start_date, pact_publication_scope)
        potential_wip_pacts_by_consumer_tag_query = PactPublication.for_provider(provider).created_after(wip_start_date).send(pact_publication_scope)
        potential_wip_pacts_by_consumer_tag = potential_wip_pacts_by_consumer_tag_query.all

        tag_to_pact_publications = provider_tags_names.each_with_object({}) do | provider_tag_name, tag_to_pact_publications |
          tag_to_pact_publications[provider_tag_name] = remove_already_verified_by_tag(
            potential_wip_pacts_by_consumer_tag,
            potential_wip_pacts_by_consumer_tag_query,
            provider,
            provider_tag_name
          )
        end

        provider_has_no_versions = !provider.any_versions?

        tag_to_pact_publications.flat_map do | provider_tag_name, pact_publications |
          pact_publications.collect do | pact_publication |
            pre_existing_tag_names = find_provider_tag_names_that_were_first_used_before_pact_published(pact_publication, provider_tags)
            pre_existing_pending_tags = [provider_tag_name] & pre_existing_tag_names

            if pre_existing_pending_tags.any? || (PactBroker.feature_enabled?(:experimental_no_provider_versions_makes_all_head_pacts_wip) && provider_has_no_versions)
              selectors = create_selectors_for_wip_pact(pact_publication)
              VerifiablePact.create_for_wip_for_provider_tags(pact_publication.to_domain, selectors, pre_existing_pending_tags)
            end
          end
        end.compact
      end

      def create_selectors_for_wip_pact(pact_publication)
        if pact_publication.values[:tag_name]
          Selectors.create_for_latest_for_tag(pact_publication.values[:tag_name])
        else
          Selectors.create_for_latest_for_branch(pact_publication.consumer_version.branch)
        end
      end

      def find_wip_pact_versions_for_provider_by_provider_branch(provider_name, provider_version_branch, options)
        provider = pacticipant_repository.find_by_name(provider_name)
        wip_start_date = options.fetch(:include_wip_pacts_since)

        wip_pact_publications_by_branch = remove_already_verified_by_branch(
          PactPublication.for_provider(provider).created_after(wip_start_date).latest_by_consumer_branch,
          provider,
          provider_version_branch
        )

        wip_pact_publications_by_tag = remove_already_verified_by_branch(
          PactPublication.for_provider(provider).created_after(wip_start_date).latest_by_consumer_tag,
          provider,
          provider_version_branch
        )

        verifiable_pacts = (wip_pact_publications_by_branch + wip_pact_publications_by_tag).collect do | pact_publication |
          selectors = create_selectors_for_wip_pact(pact_publication)
          VerifiablePact.create_for_wip_for_provider_branch(pact_publication.to_domain, selectors, provider_version_branch)
        end

        deduplicate_verifiable_pacts(verifiable_pacts).sort
      end

      def find_all_pact_versions_for_provider_with_consumer_version_tags provider_name, selector
        provider = pacticipant_repository.find_by_name(provider_name)
        consumer = selector.consumer ? pacticipant_repository.find_by_name(selector.consumer) : nil

        scope_for(PactPublication)
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
            SelectedPact.new(latest_pact_publication.to_domain, Selectors.new(selector).resolve(latest_pact_publication.consumer_version))
          end
      end

      def remove_already_verified_by_branch(pact_publications, provider, provider_version_branch)
        pact_publications.all - pact_publications.successfully_verified_by_provider_branch(provider.id, provider_version_branch).all
      end

      def remove_already_verified_by_tag(pact_publications, query, provider, tag)
        pact_publications - query.successfully_verified_by_provider_tag(provider.id, tag).all
      end
    end
  end
end
