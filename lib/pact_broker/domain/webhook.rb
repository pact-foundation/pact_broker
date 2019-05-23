require 'pact_broker/domain/webhook_request'
require 'pact_broker/messages'
require 'pact_broker/logging'
require 'pact_broker/api/contracts/webhook_contract'

module PactBroker
  module Domain
    class Webhook

      include Messages
      include Logging

      attr_accessor :uuid, :consumer, :provider, :request, :created_at, :updated_at, :events, :enabled
      attr_reader :attributes

      def initialize attributes = {}
        @attributes = attributes
        @uuid = attributes[:uuid]
        @request = attributes[:request]
        @consumer = attributes[:consumer]
        @provider = attributes[:provider]
        @events = attributes[:events]
        @enabled = attributes[:enabled]
        @created_at = attributes[:created_at]
        @updated_at = attributes[:updated_at]
      end

      def description
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
        request.build(pact: pact, verification: verification, base_url: options[:base_url]).execute(options)
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
    end
  end
end
