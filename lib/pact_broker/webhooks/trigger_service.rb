require 'pact_broker/services'

module PactBroker
  module Webhooks
    module TriggerService

      extend self
      extend PactBroker::Repositories
      extend PactBroker::Services
      include PactBroker::Logging

      def trigger_webhooks_for_new_pact(pact, webhook_options)
        webhook_service.trigger_webhooks pact, nil, PactBroker::Webhooks::WebhookEvent::CONTRACT_PUBLISHED, webhook_options
        if pact_is_new_or_newly_tagged_or_pact_has_changed_since_previous_version?(pact)
          webhook_service.trigger_webhooks pact, nil, PactBroker::Webhooks::WebhookEvent::CONTRACT_CONTENT_CHANGED, webhook_options
        else
          logger.debug "Pact content has not changed since previous version, not triggering webhooks for changed content"
        end
      end

      def trigger_webhooks_for_updated_pact(existing_pact, updated_pact, webhook_options)
        webhook_service.trigger_webhooks updated_pact, nil, PactBroker::Webhooks::WebhookEvent::CONTRACT_PUBLISHED, webhook_options
        # TODO this should use the sha!
        if existing_pact.pact_version_sha != updated_pact.pact_version_sha
          logger.debug "Existing pact for version #{existing_pact.consumer_version_number} has been updated with new content, triggering webhooks for changed content"
          webhook_service.trigger_webhooks updated_pact, nil, PactBroker::Webhooks::WebhookEvent::CONTRACT_CONTENT_CHANGED, webhook_options
        else
          logger.debug "Pact content has not changed since previous revision, not triggering webhooks for changed content"
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
          logger.debug("Webhook triggered for the following reasons: #{messages.join(',')}" )
        end
      end
    end
  end
end
