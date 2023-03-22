require "delegate"
require "pact_broker/repositories"
require "pact_broker/services"
require "pact_broker/logging"
require "base64"
require "securerandom"
require "pact_broker/webhooks/job"
require "pact_broker/webhooks/triggered_webhook"
require "pact_broker/webhooks/status"
require "pact_broker/webhooks/webhook_event"
require "pact_broker/verifications/placeholder_verification"
require "pact_broker/pacts/placeholder_pact"
require "pact_broker/api/decorators/webhook_decorator"
require "pact_broker/hash_refinements"
require "pact_broker/webhooks/execution_configuration"
require "pact_broker/messages"
require "pact_broker/webhooks/pact_and_verification_parameters"
require "pact_broker/feature_toggle"

module PactBroker
  module Webhooks
    module Service
      using PactBroker::HashRefinements
      extend self
      extend Forwardable
      extend Repositories
      extend Services
      include Logging
      extend PactBroker::Messages

      delegate [
        :create,
        :find_by_uuid,
        :find_all,
        :update_triggered_webhook_status,
        :any_webhooks_configured_for_pact?,
        :find_by_consumer_and_provider,
        :find_latest_triggered_webhooks_for_pact,
        :fail_retrying_triggered_webhooks,
        :find_triggered_webhooks_for_pact,
        :find_triggered_webhooks_for_verification,
        :delete_by_uuid
      ] => :webhook_repository


      def next_uuid
        SecureRandom.urlsafe_base64
      end

      def update_by_uuid uuid, params
        webhook = webhook_repository.find_by_uuid(uuid)
        maintain_redacted_params(webhook, params)
        PactBroker::Api::Decorators::WebhookDecorator.new(webhook).from_hash(params)
        webhook_repository.update_by_uuid uuid, webhook
      end

      def delete_all_webhhook_related_objects_by_pacticipant pacticipant
        webhook_repository.delete_by_pacticipant(pacticipant)
      end

      def delete_all_webhook_related_objects_by_pact_publication_ids pact_publication_ids
        webhook_repository.delete_triggered_webhooks_by_pact_publication_ids pact_publication_ids
      end

      def delete_all_webhook_related_objects_by_verification_ids verification_ids
        webhook_repository.delete_triggered_webhooks_by_verification_ids verification_ids
      end

      def parameters
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
      def maintain_redacted_params(webhook, params)
        if webhook.request.password && password_key_does_not_exist_or_is_starred?(params)
          params["request"]["password"] = webhook.request.password
        end

        new_headers = params["request"]["headers"] ||= {}
        existing_headers = webhook.request.headers
        starred_new_headers = new_headers.select { |_key, value| value =~ /^\**$/ }
        starred_new_headers.each do | (key, _value) |
          new_headers[key] = existing_headers[key]
        end
        params["request"]["headers"] = new_headers
        params
      end

      def password_key_does_not_exist_or_is_starred?(params)
        !params["request"].key?("password") || params.dig("request","password") =~ /^\**$/
      end
    end
  end
end
