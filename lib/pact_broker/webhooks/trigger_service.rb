require 'pact_broker/services'
require 'pact_broker/hash_refinements'

module PactBroker
  module Webhooks
    module TriggerService

      TriggerResult = Struct.new(:message, :triggered_webhooks)

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


      def trigger_webhooks_for_new_pact(pact, event_context, webhook_options)
        trigger_results = []
        triggered_webhooks = trigger_webhooks pact, nil, PactBroker::Webhooks::WebhookEvent::CONTRACT_PUBLISHED, event_context, webhook_options
        trigger_results << TriggerResult.new("Pact published", triggered_webhooks)
        changed, explanation = pact_is_new_or_newly_tagged_or_pact_has_changed_since_previous_version?(pact)
        if changed
          triggered_webhooks = trigger_webhooks pact, nil, PactBroker::Webhooks::WebhookEvent::CONTRACT_CONTENT_CHANGED, event_context, webhook_options
          trigger_results << TriggerResult.new(explanation, triggered_webhooks)
        else
          trigger_results << TriggerResult.new("Pact content has not changed since previous version, not triggering webhooks for changed content")
        end
        trigger_results
      end

      def trigger_webhooks_for_updated_pact(existing_pact, updated_pact, event_context, webhook_options)
        trigger_results = []
        triggered_webhooks = trigger_webhooks updated_pact, nil, PactBroker::Webhooks::WebhookEvent::CONTRACT_PUBLISHED, event_context, webhook_options
        trigger_results << TriggerResult.new("Pact published", triggered_webhooks)
        if existing_pact.pact_version_sha != updated_pact.pact_version_sha
          message = "Existing pact for version #{existing_pact.consumer_version_number} has been updated with new content, triggering webhooks for changed content"
          triggered_webhooks = trigger_webhooks updated_pact, nil, PactBroker::Webhooks::WebhookEvent::CONTRACT_CONTENT_CHANGED, event_context, webhook_options
          trigger_results << TriggerResult.new(message, triggered_webhooks)
        else
          trigger_results << TriggerResult.new("Pact content has not changed since previous revision, not triggering webhooks for changed content")
        end
        trigger_results
      end

      def trigger_webhooks_for_verification_results_publication(pact, verification, event_context, webhook_options)
        expand_events(event_context).each do | reconstituted_event_context |
          # The pact passed in is the most recent one with the matching SHA.
          # Find the pact with the right consumer version number
          pact_for_triggered_webhook = find_pact_for_verification_triggered_webhook(pact, reconstituted_event_context)
          if verification.success
            trigger_webhooks(
              pact_for_triggered_webhook,
              verification,
              PactBroker::Webhooks::WebhookEvent::VERIFICATION_SUCCEEDED,
              reconstituted_event_context,
              webhook_options
            )
          else
            trigger_webhooks(
              pact_for_triggered_webhook,
              verification,
              PactBroker::Webhooks::WebhookEvent::VERIFICATION_FAILED,
              reconstituted_event_context,
              webhook_options
            )
          end

          trigger_webhooks(
            pact_for_triggered_webhook,
            verification,
            PactBroker::Webhooks::WebhookEvent::VERIFICATION_PUBLISHED,
            reconstituted_event_context,
            webhook_options
          )
        end
      end

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

      def trigger_webhooks pact, verification, event_name, event_context, options
        webhooks = webhook_repository.find_by_consumer_and_or_provider_and_event_name pact.consumer, pact.provider, event_name

        if webhooks.any?
          webhook_execution_configuration = options.fetch(:webhook_execution_configuration).with_webhook_context(event_name: event_name)
          # bit messy to merge in base_url here, but easier than a big refactor
          base_url = options.fetch(:webhook_execution_configuration).webhook_context.fetch(:base_url)

          run_webhooks_later(webhooks, pact, verification, event_name, event_context.merge(event_name: event_name, base_url: base_url), options.merge(webhook_execution_configuration: webhook_execution_configuration))
        else
          logger.info "No enabled webhooks found for consumer \"#{pact.consumer.name}\" and provider \"#{pact.provider.name}\" and event #{event_name}"
          []
        end
      end

      def run_webhooks_later webhooks, pact, verification, event_name, event_context, options
        webhooks.flat_map do | webhook |
          if PactBroker.feature_enabled?(:expand_currently_deployed_provider_versions) && webhook.expand_currently_deployed_provider_versions?
            deployed_version_service.find_currently_deployed_versions_for_pacticipant(pact.provider).collect(&:version_number).uniq.each_with_index do | version_number, index |
              schedule_webhook(webhook, pact, verification, event_name, event_context.merge(currently_deployed_provider_version_number: version_number), options, index * 5)
            end
          else
            schedule_webhook(webhook, pact, verification, event_name, event_context, options)
          end
        end
      end

      def schedule_webhook(webhook, pact, verification, event_name, event_context, options, extra_delay = 0)
        begin
          trigger_uuid = next_uuid
          triggered_webhook = webhook_repository.create_triggered_webhook(trigger_uuid, webhook, pact, verification, RESOURCE_CREATION, event_name, event_context)
          logger.info "Scheduling job for webhook with uuid #{webhook.uuid}, context: #{event_context}"
          logger.debug "Schedule webhook with options #{options}"
          job_data = { triggered_webhook: triggered_webhook }.deep_merge(options)
          # Delay slightly to make sure the request transaction has finished before we execute the webhook
          Job.perform_in(5 + extra_delay, job_data)
          triggered_webhook
        rescue StandardError => e
          logger.warn("Error scheduling webhook execution for webhook with uuid #{webhook.uuid}", e)
          nil
        end
      end

      private

      def pact_is_new_or_newly_tagged_or_pact_has_changed_since_previous_version? pact
        changed_pacts = pact_repository
          .find_previous_pacts(pact)
          .reject { |_, previous_pact| !sha_changed_or_no_previous_version?(previous_pact, pact) }
        explanation = print_debug_messages(changed_pacts)
        return changed_pacts.any?, explanation
      end

      def sha_changed_or_no_previous_version?(previous_pact, new_pact)
        previous_pact.nil? || new_pact.pact_version_sha != previous_pact.pact_version_sha
      end

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
      def expand_events(event_context)
        triggers = if event_context[:consumer_version_selectors].is_a?(Array)
          event_context[:consumer_version_selectors]
            .group_by{ | selector | selector[:consumer_version_number] }
            .collect { | consumer_version_number, selectors | merge_consumer_version_selectors(consumer_version_number, selectors, event_context.without(:consumer_version_selectors)) }
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

      def print_debug_messages(changed_pacts)
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
                "first time pact published with consumer version tagged #{tag}"
              end
            end
          end
          log_message = "Webhook triggered for the following reasons: #{messages.join(',')}"
          logger.info(log_message)
          log_message
        end
      end
    end
  end
end
