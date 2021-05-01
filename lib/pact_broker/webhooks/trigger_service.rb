require 'pact_broker/services'
require 'pact_broker/hash_refinements'

module PactBroker
  module Webhooks
    module TriggerService
      RESOURCE_CREATION = PactBroker::Webhooks::TriggeredWebhook::TRIGGER_TYPE_RESOURCE_CREATION
      USER = PactBroker::Webhooks::TriggeredWebhook::TRIGGER_TYPE_USER

      extend self
      extend PactBroker::Repositories
      extend PactBroker::Services
      include PactBroker::Logging
      using PactBroker::HashRefinements

      def next_uuid
        SecureRandom.uuid
      end

      # TODO support currently deployed
      def test_execution webhook, event_context, execution_configuration
        merged_options = execution_configuration.with_failure_log_message("Webhook execution failed").to_hash

        verification = nil
        if webhook.trigger_on_provider_verification_published?
          verification = verification_service.search_for_latest(webhook.consumer_name, webhook.provider_name) || PactBroker::Verifications::PlaceholderVerification.new
        end

        pact = pact_service.search_for_latest_pact(consumer_name: webhook.consumer_name, provider_name: webhook.provider_name) || PactBroker::Pacts::PlaceholderPact.new
        webhook.execute(pact, verification, event_context.merge(event_name: "test"), merged_options)
      end

      def execute_triggered_webhook_now triggered_webhook, webhook_execution_configuration_hash
        webhook_execution_result = triggered_webhook.execute webhook_execution_configuration_hash
        webhook_repository.create_execution triggered_webhook, webhook_execution_result
        webhook_execution_result
      end

      # the main entry point
      def create_triggered_webhooks_for_event pact, verification, event_name, event_context
        webhooks = webhook_repository.find_webhooks_to_trigger(consumer: pact.consumer, provider: pact.provider, event_name: event_name)

        if webhooks.any?
          create_triggered_webhooks_for_webhooks(webhooks, pact, verification, event_name, event_context.merge(event_name: event_name))
        else
          []
        end
      end

      # private
      def create_triggered_webhooks_for_webhooks webhooks, pact, verification, event_name, event_context
        webhooks.flat_map do | webhook |
          expanded_event_contexts = expand_events_for_currently_deployed_environments(webhook, pact, event_context)
          expanded_event_contexts = expanded_event_contexts.flat_map { | ec | expand_events_for_verification_of_multiple_selected_pacts(ec) }

          expanded_event_contexts.collect do | event_context |
            pact_for_triggered_webhook = verification ? find_pact_for_verification_triggered_webhook(pact, event_context) : pact
            webhook_repository.create_triggered_webhook(next_uuid, webhook, pact_for_triggered_webhook, verification, RESOURCE_CREATION, event_name, event_context)
          end
        end
      end

      def schedule_webhooks(triggered_webhooks, options)
        triggered_webhooks.each_with_index do | triggered_webhook, i |
          logger.info "Scheduling job for webhook with uuid #{triggered_webhook.webhook.uuid}, context: #{triggered_webhook.event_context}"
          logger.debug "Schedule webhook with options #{options}"

          job_data = { triggered_webhook: triggered_webhook }.deep_merge(options)
          begin
            # Delay slightly to make sure the request transaction has finished before we execute the webhook
            Job.perform_in(5 + (i * 3), job_data)
          rescue StandardError => e
            logger.warn("Error scheduling webhook execution for webhook with uuid #{triggered_webhook&.webhook&.uuid}", e)
            nil
          end
        end
      end

      private

      def merge_consumer_version_selectors(consumer_version_number, selectors, event_context)
        event_context.merge(
          consumer_version_number: consumer_version_number,
          consumer_version_tags: selectors.collect{ | selector | selector[:tag] }.compact.uniq
        )
      end

      # Now that we de-duplicate the pact contents when verifying though the 'pacts for verification' API,
      # we no longer get a webhook triggered for the verification results publication of each indiviual
      # consumer version tag, meaning that only the most recent commit will get the updated verification status.
      # To fix this, each URL of the pacts returned by the 'pacts for verification' API now contains the
      # relevant selectors in the metadata, so that when the verification results are published,
      # we can parse that metadata, and trigger one webhook for each consumer version like we used to.
      # Actually, we used to trigger one webhook per tag, but given that the most likely use of the
      # verification published webhook is for reporting git statuses,
      # it makes more sense to trigger per consumer version number (ie. commit).
      def expand_events_for_verification_of_multiple_selected_pacts(event_context)
        triggers = if event_context[:consumer_version_selectors].is_a?(Array)
          event_context[:consumer_version_selectors]
            .group_by{ | selector | selector[:consumer_version_number] }
            .collect { | consumer_version_number, selectors | merge_consumer_version_selectors(consumer_version_number, selectors, event_context.without(:consumer_version_selectors)) }
        else
          [event_context]
        end
      end

      def expand_events_for_currently_deployed_environments(webhook, pact, event_context)
        if PactBroker.feature_enabled?(:expand_currently_deployed_provider_versions) && webhook.expand_currently_deployed_provider_versions?
          deployed_version_service.find_currently_deployed_versions_for_pacticipant(pact.provider).collect(&:version_number).uniq.collect do | version_number |
            event_context.merge(currently_deployed_provider_version_number: version_number)
          end
        else
          [event_context]
        end
      end

      def find_pact_for_verification_triggered_webhook(pact, reconstituted_event_context)
        if reconstituted_event_context[:consumer_version_number]
          find_pact_params = {
            consumer_name: pact.consumer_name,
            provider_name: pact.provider_name,
            consumer_version_number: reconstituted_event_context[:consumer_version_number]
          }
          pact_service.find_pact(find_pact_params) || pact
        else
          pact
        end
      end
    end
  end
end
