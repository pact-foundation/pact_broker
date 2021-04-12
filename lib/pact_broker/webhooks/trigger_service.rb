require 'pact_broker/services'
require 'pact_broker/hash_refinements'

module PactBroker
  module Webhooks
    module TriggerService

      extend self
      extend PactBroker::Repositories
      extend PactBroker::Services
      include PactBroker::Logging
      using PactBroker::HashRefinements

      def trigger_webhooks_for_new_pact(pact, event_context, webhook_options)
        webhook_service.trigger_webhooks pact, nil, PactBroker::Webhooks::WebhookEvent::CONTRACT_PUBLISHED, event_context, webhook_options
        if pact_is_new_or_newly_tagged_or_pact_has_changed_since_previous_version?(pact)
          webhook_service.trigger_webhooks pact, nil, PactBroker::Webhooks::WebhookEvent::CONTRACT_CONTENT_CHANGED, event_context, webhook_options
        else
          logger.info "Pact content has not changed since previous version, not triggering webhooks for changed content"
        end
      end

      def trigger_webhooks_for_updated_pact(existing_pact, updated_pact, event_context, webhook_options)
        webhook_service.trigger_webhooks updated_pact, nil, PactBroker::Webhooks::WebhookEvent::CONTRACT_PUBLISHED, event_context, webhook_options
        if existing_pact.pact_version_sha != updated_pact.pact_version_sha
          logger.info "Existing pact for version #{existing_pact.consumer_version_number} has been updated with new content, triggering webhooks for changed content"
          webhook_service.trigger_webhooks updated_pact, nil, PactBroker::Webhooks::WebhookEvent::CONTRACT_CONTENT_CHANGED, event_context, webhook_options
        else
          logger.info "Pact content has not changed since previous revision, not triggering webhooks for changed content"
        end
      end

      def trigger_webhooks_for_verification_results_publication(pact, verification, event_context, webhook_options)
        expand_events(event_context).each do | reconstituted_event_context |
          # The pact passed in is the most recent one with the matching SHA.
          # Find the pact with the right consumer version number
          pact_for_triggered_webhook = find_pact_for_verification_triggered_webhook(pact, reconstituted_event_context)
          if verification.success
            webhook_service.trigger_webhooks(
              pact_for_triggered_webhook,
              verification,
              PactBroker::Webhooks::WebhookEvent::VERIFICATION_SUCCEEDED,
              reconstituted_event_context,
              webhook_options
            )
          else
            webhook_service.trigger_webhooks(
              pact_for_triggered_webhook,
              verification,
              PactBroker::Webhooks::WebhookEvent::VERIFICATION_FAILED,
              reconstituted_event_context,
              webhook_options
            )
          end

          webhook_service.trigger_webhooks(
            pact_for_triggered_webhook,
            verification,
            PactBroker::Webhooks::WebhookEvent::VERIFICATION_PUBLISHED,
            reconstituted_event_context,
            webhook_options
          )
        end
      end

      private

      def pact_is_new_or_newly_tagged_or_pact_has_changed_since_previous_version? pact
        changed_pacts = pact_repository
          .find_previous_pacts(pact)
          .reject { |_, previous_pact| !sha_changed_or_no_previous_version?(previous_pact, pact) }
        print_debug_messages(changed_pacts)
        changed_pacts.any?
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
          logger.info("Webhook triggered for the following reasons: #{messages.join(',')}" )
        end
      end
    end
  end
end
