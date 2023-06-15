require "pact_broker/logging"
require "pact_broker/pacts/pact_publication"
require "pact_broker/domain"
require "pact_broker/pacts/verifiable_pact"
require "pact_broker/repositories/helpers"
require "pact_broker/pacts/selected_pact"
require "pact_broker/pacts/selector"
require "pact_broker/pacts/selectors"
require "pact_broker/feature_toggle"
require "pact_broker/repositories/scopes"

module PactBroker
  module Pacts
    # rubocop: disable Metrics/ClassLength
    class PactsForVerificationRepository
      include PactBroker::Logging
      include PactBroker::Repositories
      include PactBroker::Services
      include PactBroker::Repositories::Helpers
      include PactBroker::Repositories::Scopes

      PUBLICATION_ASSOCIATIONS_FOR_EAGER_LOAD = [
        :provider,
        :consumer,
        :consumer_version,
        :pact_version
      ]

      # @return [VerifiablePact] an array of VerifiablePact objects
      def find(provider_name, consumer_version_selectors)
        selected_pacts = find_pacts_by_selector(provider_name, consumer_version_selectors)
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
      def find_wip(provider_name, provider_version_branch, provider_tags_names, explicitly_specified_verifiable_pacts, options = {})
        # TODO not sure about this
        if provider_tags_names.empty? && provider_version_branch == nil
          log_debug_for_wip do
            logger.debug("No provider tags or branch provided. Cannot calculate WIP pacts. Returning an empty list.")
          end
          return []
        end

        if provider_version_branch
          return find_wip_pact_versions_for_provider_by_provider_branch(provider_name, provider_version_branch, explicitly_specified_verifiable_pacts, options)
        end

        provider = pacticipant_repository.find_by_name(provider_name)
        wip_start_date = options.fetch(:include_wip_pacts_since)

        wip_by_consumer_tags = find_wip_pact_versions_for_provider_by_provider_tags(
          provider,
          provider_tags_names,
          wip_start_date,
          explicitly_specified_verifiable_pacts,
          :latest_by_consumer_tag
        )

        wip_by_consumer_branches = find_wip_pact_versions_for_provider_by_provider_tags(
          provider,
          provider_tags_names,
          wip_start_date,
          explicitly_specified_verifiable_pacts,
          :latest_by_consumer_branch
        )

        deduplicate_verifiable_pacts(wip_by_consumer_tags + wip_by_consumer_branches).sort
      end

      private

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

      def find_pacts_by_selector(provider_name, consumer_version_selectors)
        provider = pacticipant_repository.find_by_name(provider_name)

        specified_selectors_or_defaults(consumer_version_selectors, provider).flat_map do | selector |
          query = scope_for(PactPublication).for_provider_and_consumer_version_selector(provider, selector)
          query.eager(*PUBLICATION_ASSOCIATIONS_FOR_EAGER_LOAD).all.collect do | pact_publication |
            create_selected_pact(pact_publication, selector)
          end
        end
      end

      def create_selected_pact(pact_publication, selector)
        resolved_selector = if selector.currently_deployed? || selector.currently_supported? || selector.in_environment?
                              environment = environment_service.find_by_name(pact_publication.values.fetch(:environment_name))
                              selector.resolve_for_environment(pact_publication.consumer_version, environment, pact_publication.values[:target])
                            else
                              selector.resolve(pact_publication.consumer_version)
                            end
        SelectedPact.new(pact_publication.to_domain, Selectors.new(resolved_selector))
      end

      def specified_selectors_or_defaults(consumer_version_selectors, provider)
        if consumer_version_selectors.empty?
          default_selectors(provider)
        else
          consumer_version_selectors
        end
      end

      def default_selectors(provider)
        selectors = selector_for_latest_main_version_or_overall_latest(provider)
        selectors << Selector.for_currently_deployed
        selectors << Selector.for_currently_supported
        logger.debug("Default selectors", selectors)
        selectors
      end

      def selector_for_latest_main_version_or_overall_latest(provider)
        selectors = Selectors.new
        consumers = integration_service.find_for_provider(provider).collect(&:consumer)

        consumers.collect do | consumer |
          if consumer.main_branch && PactBroker::Domain::Version.for_selector(PactBroker::Matrix::UnresolvedSelector.new(branch: consumer.main_branch, pacticipant_name: consumer.name, latest: true)).any?
            selectors << Selector.for_main_branch.for_consumer(consumer.name)
          elsif consumer.main_branch && PactBroker::Domain::Version.for_selector(PactBroker::Matrix::UnresolvedSelector.new(tag: consumer.main_branch, pacticipant_name: consumer.name, latest: true)).any?
            selectors << Selector.latest_for_tag(consumer.main_branch).for_consumer(consumer.name)
          else
            selectors << Selector.overall_latest.for_consumer(consumer.name)
          end
        end

        selectors
      end

      def find_pacts_for_which_the_latest_version_for_the_fallback_tag_is_required(provider_name, selectors)
        selectors.collect do | selector |
          query = scope_for(PactPublication).eager_for_domain_with_content.for_provider_name(provider_name).for_latest_consumer_versions_with_tag(selector.fallback_tag)
          query = query.for_consumer_name(selector.consumer) if selector.consumer
          query.all.collect do | pact_publication |
            SelectedPact.new(
              pact_publication.to_domain,
              Selectors.new(selector.resolve_for_fallback(pact_publication.consumer_version))
            )
          end
        end.flatten
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
        SelectedPact.merge_by_pact_version_sha(selected_pacts)
      end

      # TODO ? find the WIP pacts by consumer branch
      def find_wip_pact_versions_for_provider_by_provider_tags(provider, provider_tags_names, wip_start_date, explicitly_specified_verifiable_pacts, pact_publication_scope)
        potential_wip_pacts_by_consumer_tag_query = PactPublication.for_provider(provider).created_after(wip_start_date).send(pact_publication_scope)

        log_debug_for_wip do
          log_pact_publications_from_query("Potential WIP pacts for provider tag(s) #{provider_tags_names.join(", ")} created after #{wip_start_date} by #{pact_publication_scope}", potential_wip_pacts_by_consumer_tag_query)
        end

        tag_to_pact_publications = provider_tags_names.each_with_object({}) do | provider_tag_name, tag_to_pact_publication |
          tag_to_pact_publication[provider_tag_name] = remove_non_wip_for_tag(
            potential_wip_pacts_by_consumer_tag_query,
            provider,
            provider_tag_name,
            explicitly_specified_verifiable_pacts
          )
        end

        tag_to_pact_publications.flat_map do | provider_tag_name, pact_publications |
          pact_publications.collect do | pact_publication |
            selectors = create_selectors_for_wip_pact(pact_publication)
            VerifiablePact.create_for_wip_for_provider_tags(pact_publication.to_domain, selectors, [provider_tag_name])
          end
        end.compact
      end

      def create_selectors_for_wip_pact(pact_publication)
        if pact_publication.values[:tag_name]
          Selectors.create_for_latest_for_tag(pact_publication.values[:tag_name])
        else
          Selectors.create_for_latest_for_branch(pact_publication.values.fetch(:branch_name))
        end
      end

      def find_wip_pact_versions_for_provider_by_provider_branch(provider_name, provider_version_branch, explicitly_specified_verifiable_pacts, options)
        provider = pacticipant_repository.find_by_name(provider_name)
        wip_start_date = options.fetch(:include_wip_pacts_since)

        potential_wip_by_consumer_branch = PactPublication.for_provider(provider).created_after(wip_start_date).latest_by_consumer_branch
        potential_wip_by_consumer_tag = PactPublication.for_provider(provider).created_after(wip_start_date).latest_by_consumer_tag

        log_debug_for_wip do
          log_pact_publications_from_query("Potential WIP pacts for provider branch #{provider_version_branch} created after #{wip_start_date} by consumer branch", potential_wip_by_consumer_branch)
          log_pact_publications_from_query("Potential WIP pacts for provider branch #{provider_version_branch} created after #{wip_start_date} by consumer tag", potential_wip_by_consumer_tag)
        end

        wip_pact_publications_by_branch = remove_non_wip_for_branch(
          potential_wip_by_consumer_branch,
          provider,
          provider_version_branch,
          explicitly_specified_verifiable_pacts
        )

        wip_pact_publications_by_tag = remove_non_wip_for_branch(
          potential_wip_by_consumer_tag,
          provider,
          provider_version_branch,
          explicitly_specified_verifiable_pacts
        )

        verifiable_pacts = (wip_pact_publications_by_branch + wip_pact_publications_by_tag).collect do | pact_publication |
          selectors = create_selectors_for_wip_pact(pact_publication)
          VerifiablePact.create_for_wip_for_provider_branch(pact_publication.to_domain, selectors, provider_version_branch)
        end

        deduplicate_verifiable_pacts(verifiable_pacts).sort
      end

      def remove_non_wip_for_branch(pact_publications_query, provider, provider_version_branch, explicitly_specified_verifiable_pacts)
        verified_by_this_branch = pact_publications_query.successfully_verified_by_provider_branch_when_not_wip(provider.id, provider_version_branch)
        verified_by_other_branch = pact_publications_query.successfully_verified_by_provider_another_branch_before_this_branch_first_created(provider.id, provider_version_branch)

        log_debug_for_wip do
          log_pact_publications("Ignoring pacts explicitly specified in the selectors", explicitly_specified_verifiable_pacts)
          log_pact_publications_from_query("Ignoring pacts successfully verified by this provider branch when not WIP", verified_by_this_branch)
          log_pact_publications_from_query("Ignoring pacts successfully verified by another provider branch when not WIP", verified_by_other_branch)
        end

        remove_explicitly_specified_verifiable_pacts(PactPublication.subtract(
            pact_publications_query.eager(*PUBLICATION_ASSOCIATIONS_FOR_EAGER_LOAD).all,
            verified_by_this_branch.all,
            verified_by_other_branch.all),
          explicitly_specified_verifiable_pacts)
      end

      def remove_non_wip_for_tag(pact_publications_query, provider, tag, explicitly_specified_verifiable_pacts)
        verified_by_this_tag = pact_publications_query.successfully_verified_by_provider_tag_when_not_wip(tag)
        verified_by_another_tag = pact_publications_query.successfully_verified_by_provider_another_tag_before_this_tag_first_created(provider.id, tag)

        log_debug_for_wip do
          log_pact_publications("Ignoring pacts explicitly specified in the selectors", explicitly_specified_verifiable_pacts)
          log_pact_publications_from_query("Ignoring pacts successfully verified by this provider tag when not WIP", verified_by_this_tag)
          log_pact_publications_from_query("Ignoring pacts successfully verified by another provider tag when not WIP", verified_by_another_tag)
        end

        remove_explicitly_specified_verifiable_pacts(
          PactPublication.subtract(
            pact_publications_query.eager(*PUBLICATION_ASSOCIATIONS_FOR_EAGER_LOAD).all,
            verified_by_this_tag.all,
            verified_by_another_tag.all),
          explicitly_specified_verifiable_pacts)
      end

      def remove_explicitly_specified_verifiable_pacts(pact_publications, explicitly_specified_verifiable_pacts)
        pact_publications.reject do | pact_publication |
          explicitly_specified_verifiable_pacts.find{ | explict_pact |
            explict_pact.consumer.id == pact_publication.consumer_id &&
              explict_pact.provider.id == pact_publication.provider_id &&
              explict_pact.pact_version_sha == pact_publication.pact_version_sha
          }
        end
      end

      def collect_consumer_name_and_version_number(pact_publications)
        pact_publications.collect do |p|
          suffix =  if p.respond_to?(:values)
                      if p.values[:tag_name]
                        " (tag #{p.values[:tag_name]})"
                      elsif p.values[:branch_name]
                        " (branch #{p.values[:branch_name]})"
                      else
                        ""
                      end
                    else
                      ""
                    end

          "#{p.consumer.name} #{p.consumer_version.number}" + suffix
        end
      end

      def with_sorted_eager_fields(pact_publications_query)
        pact_publications_query
          .eager(:provider)
          .eager(:consumer, :consumer_version)
          .order(:consumer_version_order)
          .all_forbidding_lazy_load
          .sort
      end

      def log_pact_publications_from_query(message, pact_publications_query)
        pact_publication_descriptions = collect_consumer_name_and_version_number(with_sorted_eager_fields(pact_publications_query))
        if pact_publication_descriptions.any?
          logger.debug("#{message}", pact_publication_descriptions)
        else
          logger.debug("#{message} (none)")
        end
      end

      def log_pact_publications(message, pact_publications)
        pact_publication_descriptions = collect_consumer_name_and_version_number(pact_publications)
        if pact_publication_descriptions.any?
          logger.debug("#{message}", pact_publication_descriptions)
        else
          logger.debug("#{message} (none)")
        end
      end

      def log_debug_for_wip
        if logger.debug?
          log_with_tag(:wip) do
            yield
          end
        end
      end
    end
    # rubocop: enable Metrics/ClassLength
  end
end
