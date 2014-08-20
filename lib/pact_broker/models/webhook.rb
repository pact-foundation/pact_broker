require 'pact_broker/models/webhook_request'
require 'pact_broker/messages'
require 'pact_broker/logging'

module PactBroker

  module Models

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

      def validate
        messages = []
        messages << message('errors.validation.attribute_missing', attribute: 'request') unless request
        messages.concat request.validate if request
        messages
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
        "webhook for consumer=#{consumer.name} provider=#{provider.name} uuid=#{uuid} request=#{request}"
      end
    end

  end

end
