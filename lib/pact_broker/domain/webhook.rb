require "pact_broker/domain/webhook_request"
require "pact_broker/messages"
require "pact_broker/logging"
require "pact_broker/api/contracts/webhook_contract"
require "pact_broker/webhooks/http_request_with_redacted_headers"
require "pact_broker/webhooks/pact_and_verification_parameters"

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
        attributes.each do | (name, value) |
          instance_variable_set("@#{name}", value) if respond_to?(name)
        end
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
          "A webhook for the pact between #{consumer_name} and #{provider_name}"
        elsif provider
          "A webhook for all pacts with provider #{provider_name}"
        elsif consumer
          "A webhook for all pacts with consumer #{consumer_name}"
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
        webhook_request = request.build(template_params, **options.slice(:user_agent, :disable_ssl_verification, :cert_store))
        http_response, error = execute_request(webhook_request)
        success = success?(http_response, options)
        http_request = webhook_request.http_request
        logs = generate_logs(webhook_request, http_response, success, error, event_context, options.fetch(:logging_options))
        result(http_request, http_response, success, logs, error)
      end

      def to_s
        "webhook for consumer=#{consumer_name} provider=#{provider_name} uuid=#{uuid}"
      end

      def consumer_name
        consumer && (consumer.name || (consumer.label && "#{provider ? 'consumers ' : ''}labeled '#{consumer.label}'"))
      end

      def provider_name
        provider && (provider.name || (provider.label && "#{consumer ? 'providers ' : ''}labeled '#{provider.label}'"))
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

      def trigger_on_contract_requiring_verification_published?
        events.any?(&:contract_requiring_verification_published?)
      end

      def expand_currently_deployed_provider_versions?
        request.uses_parameter?(PactBroker::Webhooks::PactAndVerificationParameters::CURRENTLY_DEPLOYED_PROVIDER_VERSION_NUMBER)
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

      def template_parameters(pact, verification, event_context, _options)
        PactBroker::Webhooks::PactAndVerificationParameters.new(pact, verification, event_context).to_hash
      end

      def success?(http_response, options)
        !http_response.nil? && options.fetch(:http_success_codes).include?(http_response.code.to_i)
      end

      # rubocop: disable Metrics/ParameterLists
      def generate_logs(webhook_request, http_response, success, error, event_context, logging_options)
        webhook_request_logger = PactBroker::Webhooks::WebhookRequestLogger.new(logging_options)
        webhook_request_logger.log(
          uuid,
          webhook_request,
          http_response,
          success,
          error,
          event_context
        )
      end
      # robocop: enable Metrics/ParameterLists

      def result(http_request, http_response, success, logs, error)
        PactBroker::Webhooks::WebhookExecutionResult.new(
          http_request,
          http_response,
          success,
          logs,
          error
        )
      end
    end
  end
end
