require 'pact_broker/domain/webhook_request'
require 'pact_broker/messages'
require 'pact_broker/logging'
require 'pact_broker/api/contracts/webhook_contract'

module PactBroker

  module Domain

    class Webhook

      include Messages
      include Logging

      attr_accessor :uuid, :consumer, :provider, :request, :created_at, :updated_at

      def initialize attributes = {}
        @uuid = attributes[:uuid]
        @request = attributes[:request]
        @consumer = attributes[:consumer]
        @provider = attributes[:provider]
        @created_at = attributes[:created_at]
        @updated_at = attributes[:updated_at]
      end

      def description
        "A webhook for the pact between #{consumer.name} and #{provider.name}"
      end

      def request_description
        request && request.description
      end

      #TODO retries
      def execute
        logger.info "Executing #{self}"
        request.execute
      end

      def to_s
        "webhook for consumer=#{consumer_name} provider=#{provider_name} uuid=#{uuid} request=#{request}"
      end

      def consumer_name
        consumer && consumer.name
      end

      def provider_name
        provider && provider.name
      end
    end

  end

end
