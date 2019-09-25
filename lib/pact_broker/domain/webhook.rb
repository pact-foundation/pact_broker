require 'pact_broker/domain/webhook_request'
require 'pact_broker/messages'
require 'pact_broker/logging'
require 'pact_broker/api/contracts/webhook_contract'
require 'pact_broker/webhooks/http_request_with_redacted_headers'

module PactBroker
  module Domain
    class Webhook

      include Messages
      include Logging

      # request is actually a request_template
      attr_accessor :uuid, :consumer, :provider, :request, :created_at, :updated_at, :events, :enabled, :description
      attr_reader :attributes

      def initialize attributes = {}
        @attributes = attributes
        @uuid = attributes[:uuid]
        @description = attributes[:description]
        @request = attributes[:request]
        @consumer = attributes[:consumer]
        @provider = attributes[:provider]
        @events = attributes[:events]
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

      def execute pact, verification, options
        logger.info "Executing #{self}"
        webhook_request = request.build(template_parameters(pact, verification, options))
        http_response, error = execute_request(webhook_request)

        PactBroker::Webhooks::WebhookExecutionResult.new(
          webhook_request.http_request,
          http_response,
          generate_logs(webhook_request, http_response, error, options.fetch(:logging_options)),
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

      def template_parameters(pact, verification, options)
        PactBroker::Webhooks::PactAndVerificationParameters.new(pact, verification, options.fetch(:webhook_context)).to_hash
      end

      def generate_logs(webhook_request, http_response, error, logging_options)
        webhook_request_logger = PactBroker::Webhooks::WebhookRequestLogger.new(logging_options)
        webhook_request_logger.log(
          uuid,
          webhook_request,
          http_response,
          error
        )
      end
    end
  end
end
