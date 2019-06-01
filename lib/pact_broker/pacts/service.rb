require 'pact_broker/repositories'
require 'pact_broker/services'
require 'pact_broker/logging'
require 'pact_broker/pacts/merger'
require 'pact_broker/pacts/verifiable_pact'

module PactBroker
  module Pacts
    module Service

      extend self

      extend PactBroker::Repositories
      extend PactBroker::Services
      include PactBroker::Logging

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

      def create_or_update_pact params, webhook_options
        provider = pacticipant_repository.find_by_name_or_create params[:provider_name]
        consumer = pacticipant_repository.find_by_name_or_create params[:consumer_name]
        consumer_version = version_repository.find_by_pacticipant_id_and_number_or_create consumer.id, params[:consumer_version_number]
        existing_pact = pact_repository.find_by_version_and_provider(consumer_version.id, provider.id)

        if existing_pact
          update_pact params, existing_pact, webhook_options
        else
          create_pact params, consumer_version, provider, webhook_options
        end
      end

      def merge_pact params, webhook_options
        provider = pacticipant_repository.find_by_name_or_create params[:provider_name]
        consumer = pacticipant_repository.find_by_name_or_create params[:consumer_name]
        consumer_version = version_repository.find_by_pacticipant_id_and_number_or_create consumer.id, params[:consumer_version_number]
        existing_pact = pact_repository.find_by_version_and_provider(consumer_version.id, provider.id)

        params.merge!(json_content: Merger.merge_pacts(existing_pact.json_content, params[:json_content]))

        update_pact params, existing_pact, webhook_options
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

      def find_latest_pact_versions_for_provider provider_name, options = {}
        pact_repository.find_latest_pact_versions_for_provider provider_name, options[:tag]
      end

      def find_wip_pact_versions_for_provider provider_name
        pact_repository.find_wip_pact_versions_for_provider provider_name
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

      def find_for_verification(provider_name, provider_version_tags, consumer_version_selectors)
        pact_repository
          .find_for_verification(provider_name, consumer_version_selectors)
          .group_by(&:pact_version_sha)
          .collect do | pact_version_sha, head_pacts |

            domain_pact = head_pacts.first.pact
            pending_provider_tags = []
            pending = nil
            if provider_version_tags.any?
              pending_provider_tags = provider_version_tags.select do | provider_version_tag |
                pact.pending?([provider_version_tag])
              end
              pending = pending_provider_tags.any?
            else
              pending = pact.pending?
            end

            head_consumer_tags = head_pacts.collect(&:head_tag)
            overall_latest = head_consumer_tags.include?(nil)
            VerifiablePact.new(domain_pact, pending, pending_provider_tags, head_consumer_tags.compact, overall_latest)
          end
      end

      private

      # Overwriting an existing pact with the same consumer/provider/consumer version number
      def update_pact params, existing_pact, webhook_options
        logger.info "Updating existing pact publication with params #{params.reject{ |k, v| k == :json_content}}"
        logger.debug "Content #{params[:json_content]}"
        pact_version_sha = generate_sha(params[:json_content])
        json_content = add_interaction_ids(params[:json_content])
        update_params = { pact_version_sha: pact_version_sha, json_content: json_content }
        updated_pact = pact_repository.update(existing_pact.id, update_params)

        webhook_trigger_service.trigger_webhooks_for_updated_pact(existing_pact, updated_pact, merge_consumer_version_info(webhook_options, updated_pact))

        updated_pact
      end

      # When no publication for the given consumer/provider/consumer version number exists
      def create_pact params, version, provider, webhook_options
        logger.info "Creating new pact publication with params #{params.reject{ |k, v| k == :json_content}}"
        logger.debug "Content #{params[:json_content]}"
        pact_version_sha = generate_sha(params[:json_content])
        json_content = add_interaction_ids(params[:json_content])
        pact = pact_repository.create(
          version_id: version.id,
          provider_id: provider.id,
          consumer_id: version.pacticipant_id,
          pact_version_sha: pact_version_sha,
          json_content: json_content
        )
        webhook_trigger_service.trigger_webhooks_for_new_pact(pact, merge_consumer_version_info(webhook_options, pact))
        pact
      end

      def generate_sha(json_content)
        PactBroker.configuration.sha_generator.call(json_content)
      end

      def add_interaction_ids(json_content)
        Content.from_json(json_content).with_ids.to_json
      end

      def merge_consumer_version_info(webhook_options, pact)
        webhook_context = webhook_options.fetch(:webhook_context, {}).merge(
          consumer_version_tags: pact.consumer_version_tag_names
        )
        webhook_options.merge(webhook_context: webhook_context)
      end
    end
  end
end
