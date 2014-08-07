require 'pact_broker/models/webhook_request'
require 'pact_broker/messages'

module PactBroker

  module Models

    class Webhook

      include Messages

      attr_accessor :uuid, :consumer, :provider, :request

      def initialize attributes = {}
        @uuid = attributes[:uuid]
        @request = attributes[:request]
        @consumer = attributes[:consumer]
        @provider = attributes[:provider]
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
    end

  end

end
