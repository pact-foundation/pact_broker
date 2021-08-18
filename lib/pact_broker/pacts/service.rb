require "pact_broker/repositories"
require "pact_broker/services"
require "pact_broker/logging"
require "pact_broker/pacts/merger"
require "pact_broker/pacts/verifiable_pact"
require "pact_broker/pacts/squash_pacts_for_verification"
require "pact_broker/events/publisher"
require "pact_broker/messages"
require "pact_broker/hash_refinements"

module PactBroker
  module Pacts
    module Service
      using PactBroker::HashRefinements

      extend self
      extend PactBroker::Events::Publisher

      extend PactBroker::Repositories
      extend PactBroker::Services
      include PactBroker::Logging
      extend PactBroker::Messages
      extend SquashPactsForVerification

      def find_latest_pact params
        pact_repository.find_latest_pact(params[:consumer_name], params[:provider_name], params[:tag])
      end

      def search_for_latest_pact params
        pact_repository.search_for_latest_pact(params[:consumer_name], params[:provider_name], params[:tag])
      end

      def find_latest_pacts
        pact_repository.find_latest_pacts
      end

      def find_pact params
        pact_repository.find_pact(params[:consumer_name], params[:consumer_version_number], params[:provider_name], params[:pact_version_sha])
      end

      def find_by_consumer_version params
        pact_repository.find_by_consumer_version(params[:consumer_name], params[:consumer_version_number])
      end

      def delete params
        logger.info "Deleting pact version with params #{params}"
        pacts = pact_repository.find_all_revisions(params[:consumer_name], params[:consumer_version_number], params[:provider_name])
        webhook_service.delete_all_webhook_related_objects_by_pact_publication_ids(pacts.collect(&:id))
        pact_repository.delete(params)
      end

      def create_or_update_pact params
        provider = pacticipant_repository.find_by_name_or_create params[:provider_name]
        consumer = pacticipant_repository.find_by_name_or_create params[:consumer_name]
        consumer_version = version_repository.find_by_pacticipant_id_and_number_or_create consumer.id, params[:consumer_version_number]
        existing_pact = pact_repository.find_by_version_and_provider(consumer_version.id, provider.id)

        if existing_pact
          update_pact params, existing_pact
        else
          create_pact params, consumer_version, provider
        end
      end

      def merge_pact params
        provider = pacticipant_repository.find_by_name_or_create params[:provider_name]
        consumer = pacticipant_repository.find_by_name_or_create params[:consumer_name]
        consumer_version = version_repository.find_by_pacticipant_id_and_number_or_create consumer.id, params[:consumer_version_number]
        existing_pact = pact_repository.find_by_version_and_provider(consumer_version.id, provider.id)

        params[:json_content] = Merger.merge_pacts(
          existing_pact.json_content, params[:json_content]
        )

        update_pact params, existing_pact
      end

      def find_all_pact_versions_between consumer, options
        pact_repository.find_all_pact_versions_between consumer, options
      end

      def delete_all_pact_publications_between consumer, options
        pact_repository.delete_all_pact_publications_between consumer, options
      end

      def delete_all_pact_versions_between consumer, options
        pact_repository.delete_all_pact_versions_between consumer, options
      end

      def find_latest_pacts_for_provider provider_name, options = {}
        pact_repository.find_latest_pacts_for_provider provider_name, options[:tag]
      end

      def find_pact_versions_for_provider provider_name, options = {}
        pact_repository.find_pact_versions_for_provider provider_name, options[:tag]
      end

      def find_previous_distinct_pact_version params
        pact = find_pact params
        return nil if pact.nil?
        pact_repository.find_previous_distinct_pact pact
      end

      def find_distinct_pacts_between consumer, options
        # Assumes pacts are sorted from newest to oldest
        all = pact_repository.find_all_pact_versions_between consumer, options
        distinct = []
        (0...all.size).each do | i |
          if i == all.size - 1
            distinct << all[i]
          else
            if all[i].json_content != all[i+1].json_content
              distinct << all[i]
            end
          end
        end
        distinct
      end

      def find_for_verification(provider_name, provider_version_branch, provider_version_tags, consumer_version_selectors, options)
        explicitly_specified_verifiable_pacts = pact_repository
          .find_for_verification(provider_name, consumer_version_selectors)
          .collect do | selected_pact |
            # Todo move this into the repository
            squash_pacts_for_verification(provider_version_tags, selected_pact, options[:include_pending_status])
          end

        verifiable_wip_pacts =  if options[:include_wip_pacts_since]
                                  specified_pact_version_shas = explicitly_specified_verifiable_pacts.collect(&:pact_version_sha)
                                  pact_repository.find_wip_pact_versions_for_provider(provider_name, provider_version_branch, provider_version_tags, specified_pact_version_shas, options)
                                else
                                  []
                                end

        explicitly_specified_verifiable_pacts + verifiable_wip_pacts
      end

      def find_for_verification_publication(pact_params, consumer_version_selector_hashes)
        if consumer_version_selector_hashes&.any?
          selected_pacts = consumer_version_selector_hashes.collect do | consumer_version_selector_hash |
            find_pact_params = {
              consumer_name: pact_params.consumer_name,
              provider_name: pact_params.provider_name,
              pact_version_sha: pact_params.pact_version_sha,
              consumer_version_number: consumer_version_selector_hash[:consumer_version_number]
            }
            pact = find_pact(find_pact_params)
            resolved_selector = Selector.new(consumer_version_selector_hash.without(:consumer_version_number)).resolve(pact.consumer_version)
            SelectedPact.new(pact, Selectors.new(resolved_selector))
          end
          SelectedPact.merge_by_consumer_version_number(selected_pacts)
        else
          [SelectedPact.new(find_pact(pact_params), Selectors.new)]
        end
      end

      # verified_pacts is an array of SelectedPact objects
      def set_latest_verification(verified_pacts, verification)
        if verification.from_latest_main_version?
          verified_pacts.each do | verified_pact |
            pact_repository.set_latest_main_verification(verified_pact, verification)
          end
        else
          verified_pacts.each do | verified_pact |
            pact_repository.set_last_verified_at(verified_pact)
          end
        end
      end

      # Overwriting an existing pact with the same consumer/provider/consumer version number
      def update_pact params, existing_pact
        logger.info "Updating existing pact publication with params #{params.reject{ |k, _v| k == :json_content}}"
        logger.debug "Content #{params[:json_content]}"
        pact_version_sha = generate_sha(params[:json_content])
        json_content = add_interaction_ids(params[:json_content])
        update_params = { pact_version_sha: pact_version_sha, json_content: json_content }
        updated_pact = pact_repository.update(existing_pact.id, update_params)

        event_context = { consumer_version_tags: updated_pact.consumer_version_tag_names }
        event_params = { event_context: event_context, pact: updated_pact }

        broadcast(:contract_published, event_params)

        if existing_pact.pact_version_sha != updated_pact.pact_version_sha
          broadcast(:contract_content_changed, event_params.merge(event_comment: "pact content modified since previous publication for #{updated_pact.consumer_name} version #{updated_pact.consumer_version_number}"))
        else
          broadcast(:contract_content_unchanged, event_params.merge(event_comment: "pact content was unchanged"))
        end

        updated_pact
      end

      def disallowed_modification?(existing_pact, new_json_content)
        !PactBroker.configuration.allow_dangerous_contract_modification && existing_pact && existing_pact.pact_version_sha != generate_sha(new_json_content)
      end

      private :update_pact

      # When no publication for the given consumer/provider/consumer version number exists
      def create_pact params, version, provider
        logger.info "Creating new pact publication with params #{params.reject{ |k, _v| k == :json_content}}"
        logger.debug "Content #{params[:json_content]}"
        pact_version_sha = generate_sha(params[:json_content])
        json_content = add_interaction_ids(params[:json_content])
        pact = pact_repository.create(
          version_id: version.id,
          provider_id: provider.id,
          consumer_id: version.pacticipant_id,
          pact_version_sha: pact_version_sha,
          json_content: json_content,
          version: version
        )

        event_params = { event_context: { consumer_version_tags: pact.consumer_version_tag_names }, pact: pact }
        content_changed, explanation = pact_is_new_or_newly_tagged_or_pact_has_changed_since_previous_version?(pact)

        if content_changed
          broadcast(:contract_published, event_params)
          broadcast(:contract_content_changed, event_params.merge(event_comment: explanation))
        else
          broadcast(:contract_published, event_params.merge(event_comment: contract_published_event_comment(pact)))
        end

        pact
      end

      private :create_pact

      def generate_sha(json_content)
        PactBroker.configuration.sha_generator.call(json_content)
      end

      private :generate_sha

      def add_interaction_ids(json_content)
        Content.from_json(json_content).with_ids.to_json
      end

      private :add_interaction_ids

      def pact_is_new_or_newly_tagged_or_pact_has_changed_since_previous_version? pact
        changed_pacts = pact_repository
          .find_previous_pacts(pact)
          .reject { |_, previous_pact| !sha_changed_or_no_previous_version?(previous_pact, pact) }
        explanation = explanation_for_content_changed(changed_pacts)
        return changed_pacts.any?, explanation
      end

      private :pact_is_new_or_newly_tagged_or_pact_has_changed_since_previous_version?

      def sha_changed_or_no_previous_version?(previous_pact, new_pact)
        previous_pact.nil? || new_pact.pact_version_sha != previous_pact.pact_version_sha
      end

      private :sha_changed_or_no_previous_version?

      def explanation_for_content_changed(changed_pacts)
        if changed_pacts.any?
          messages = changed_pacts.collect do |tag, previous_pact|
            if tag == :untagged
              if previous_pact
                "pact content has changed since previous untagged version"
              else
                "first time untagged pact published"
              end
            else
              if previous_pact
                "pact content has changed since the last consumer version tagged with #{tag}"
              else
                "first time any pact published for this consumer with consumer version tagged #{tag}"
              end
            end
          end
          messages.join(", ")
        end
      end

      private :explanation_for_content_changed

      def contract_published_event_comment pact
        if pact.consumer_version_tag_names.count == 1
          message("messages.events.pact_published_unchanged_with_single_tag", tag_name: pact.consumer_version_tag_names.first)
        else
          message("messages.events.pact_published_unchanged_with_multiple_tags", tag_names: pact.consumer_version_tag_names.join(", "))
        end
      end
    end
  end
end
