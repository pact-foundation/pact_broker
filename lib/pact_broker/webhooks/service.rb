require 'pact_broker/repositories'
require 'pact_broker/services'
require 'pact_broker/logging'
require 'base64'
require 'securerandom'
require 'pact_broker/webhooks/job'
require 'pact_broker/webhooks/triggered_webhook'
require 'pact_broker/webhooks/status'
require 'pact_broker/webhooks/webhook_event'
require 'pact_broker/verifications/placeholder_verification'
require 'pact_broker/pacts/placeholder_pact'
require 'pact_broker/api/decorators/webhook_decorator'
require 'pact_broker/hash_refinements'
require 'pact_broker/webhooks/execution_configuration'
require 'pact_broker/messages'
require 'pact_broker/webhooks/pact_and_verification_parameters'
require 'pact_broker/feature_toggle'

module PactBroker
  module Webhooks
    class Service
      using PactBroker::HashRefinements

      extend Repositories
      extend Services
      include Logging
      extend PactBroker::Messages

      # Not actually a UUID. Ah well.
      def self.valid_uuid_format?(uuid)
        !!(uuid =~ /^[A-Za-z0-9_\-]{16,}$/)
      end

      def self.next_uuid
        SecureRandom.urlsafe_base64
      end

      def self.errors webhook, uuid = nil
        contract = PactBroker::Api::Contracts::WebhookContract.new(webhook)
        contract.validate(webhook.attributes)
        messages = contract.errors.messages

        if uuid && !valid_uuid_format?(uuid)
          messages["uuid"] = [message("errors.validation.invalid_webhook_uuid")]
        end

        OpenStruct.new(messages: messages, empty?: messages.empty?, any?: messages.any?)
      end

      def self.create uuid, webhook, consumer, provider
        webhook_repository.create uuid, webhook, consumer, provider
      end

      def self.find_by_uuid uuid
        webhook_repository.find_by_uuid uuid
      end

      def self.update_by_uuid uuid, params
        webhook = webhook_repository.find_by_uuid(uuid)
        maintain_redacted_params(webhook, params)
        PactBroker::Api::Decorators::WebhookDecorator.new(webhook).from_hash(params)
        webhook_repository.update_by_uuid uuid, webhook
      end

      def self.delete_by_uuid uuid
        webhook_repository.delete_triggered_webhooks_by_webhook_uuid uuid
        webhook_repository.delete_by_uuid uuid
      end

      def self.delete_all_webhhook_related_objects_by_pacticipant pacticipant
        webhook_repository.delete_executions_by_pacticipant pacticipant
        webhook_repository.delete_triggered_webhooks_by_pacticipant pacticipant
        webhook_repository.delete_by_pacticipant pacticipant
      end

      def self.delete_all_webhook_related_objects_by_pact_publication_ids pact_publication_ids
        webhook_repository.delete_triggered_webhooks_by_pact_publication_ids pact_publication_ids
      end

      def self.delete_all_webhook_related_objects_by_verification_ids verification_ids
        webhook_repository.delete_triggered_webhooks_by_verification_ids verification_ids
      end

      def self.find_all
        webhook_repository.find_all
      end

      def self.update_triggered_webhook_status triggered_webhook, status
        webhook_repository.update_triggered_webhook_status triggered_webhook, status
      end

      def self.find_for_pact pact
        webhook_repository.find_for_pact(pact)
      end

      def self.find_by_consumer_and_or_provider consumer, provider
        webhook_repository.find_by_consumer_and_or_provider(consumer, provider)
      end

      def self.find_by_consumer_and_provider consumer, provider
        webhook_repository.find_by_consumer_and_provider consumer, provider
      end

      def self.find_latest_triggered_webhooks_for_pact pact
        webhook_repository.find_latest_triggered_webhooks_for_pact pact
      end

      def self.find_latest_triggered_webhooks consumer, provider
        webhook_repository.find_latest_triggered_webhooks consumer, provider
      end

      def self.fail_retrying_triggered_webhooks
        webhook_repository.fail_retrying_triggered_webhooks
      end

      def self.find_triggered_webhooks_for_pact pact
        webhook_repository.find_triggered_webhooks_for_pact(pact)
      end

      def self.find_triggered_webhooks_for_verification verification
        webhook_repository.find_triggered_webhooks_for_verification(verification)
      end

      def self.parameters
        PactAndVerificationParameters::ALL.collect do | parameter |
          OpenStruct.new(
            name: parameter,
            description: message("messages.webhooks.parameters.#{parameter}")
          )
        end
      end

      private

      # Dirty hack to maintain existing password or Authorization header if it is submitted with value ****
      # This is required because the password and Authorization header is **** out in the API response
      # for security purposes, so it would need to be re-entered with every response.
      # TODO implement proper 'secrets' management.
      def self.maintain_redacted_params(webhook, params)
        if webhook.request.password && password_key_does_not_exist_or_is_starred?(params)
          params['request']['password'] = webhook.request.password
        end

        new_headers = params['request']['headers'] ||= {}
        existing_headers = webhook.request.headers
        starred_new_headers = new_headers.select { |key, value| value =~ /^\**$/ }
        starred_new_headers.each do | (key, value) |
          new_headers[key] = existing_headers[key]
        end
        params['request']['headers'] = new_headers
        params
      end

      def self.password_key_does_not_exist_or_is_starred?(params)
        !params['request'].key?('password') || params.dig('request','password') =~ /^\**$/
      end
    end
  end
end
