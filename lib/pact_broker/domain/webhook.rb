require 'pact_broker/domain/webhook_request'
require 'pact_broker/messages'
require 'pact_broker/logging'
require 'pact_broker/api/contracts/webhook_contract'
require 'pact_broker/webhooks/http_request_with_redacted_headers'
require 'pact_broker/webhooks/pact_and_verification_parameters'

module PactBroker
  module Domain
    class Webhook

      include Messages
      include Logging

      # request is actually a request_template
      attr_accessor :uuid, :consumer, :provider, :request, :created_at, :updated_at, :events, :enabled, :description, :consumer_version_matchers
      attr_reader :attributes

      def initialize attributes = {}
        @attributes = attributes
        @uuid = attributes[:uuid]
        @description = attributes[:description]
        @request = attributes[:request]
        @consumer = attributes[:consumer]
        @provider = attributes[:provider]
        @events = attributes[:events]
        @consumer_version_matchers = attributes[:consumer_version_matchers]
        @enabled = attributes[:enabled]
        @created_at = attributes[:created_at]
        @updated_at = attributes[:updated_at]
      end

      def display_description
        if description && description.strip.size > 0
          description
        else
          request_description
        end
      end

      def scope_description
        if consumer && provider
          "A webhook for the pact between #{consumer.name} and #{provider.name}"
        elsif provider
          "A webhook for all pacts with provider #{provider.name}"
        elsif consumer
          "A webhook for all pacts with consumer #{consumer.name}"
        else
          "A webhook for all pacts"
        end
      end

      def request_description
        request && request.description
      end

      def execute pact, verification, event_context, options
        logger.info "Executing #{self} event_context=#{event_context}"
        template_params = template_parameters(pact, verification, event_context, options)
        webhook_request = request.build(template_params)
        http_response, error = execute_request(webhook_request)

        logs = generate_logs(webhook_request, http_response, error, event_context, options.fetch(:logging_options))
        http_request = webhook_request.http_request
        PactBroker::Webhooks::WebhookExecutionResult.new(
          http_request,
          http_response,
          logs,
          error
        )
      end

      def to_s
        "webhook for consumer=#{consumer_name} provider=#{provider_name} uuid=#{uuid}"
      end

      def consumer_name
        consumer && consumer.name
      end

      def provider_name
        provider && provider.name
      end

      def trigger_on_contract_content_changed?
        events.any?(&:contract_content_changed?)
      end

      def trigger_on_provider_verification_published?
        events.any?(&:provider_verification_published?)
      end

      def trigger_on_provider_verification_succeeded?
        events.any?(&:provider_verification_succeeded?)
      end

      def trigger_on_provider_verification_failed?
        events.any?(&:provider_verification_failed?)
      end

      def expand_currently_deployed_provider_versions?
        request.uses_parameter?(PactBroker::Webhooks::PactAndVerificationParameters::CURRENTLY_DEPLOYED_PROVIDER_VERSION_NUMBER)
      end

      def version_matches_consumer_version_matchers?(version)
        if consumer_version_matchers&.any?
          consumer_version_matchers.any? do | matcher |
            version.matches_webhook_matcher?(matcher)
          end
        else
          true
        end
      end

      private

      def execute_request(webhook_request)
        http_response = nil
        error = nil
        begin
          http_response = webhook_request.execute
        rescue StandardError => e
          error = e
        end
        return http_response, error
      end

      def template_parameters(pact, verification, event_context, options)
        PactBroker::Webhooks::PactAndVerificationParameters.new(pact, verification, event_context).to_hash
      end

      def generate_logs(webhook_request, http_response, error, event_context, logging_options)
        webhook_request_logger = PactBroker::Webhooks::WebhookRequestLogger.new(logging_options)
        webhook_request_logger.log(
          uuid,
          webhook_request,
          http_response,
          error,
          event_context
        )
      end
    end
  end
end
