require 'pact_broker/models/webhook_request'
require 'pact_broker/messages'

module PactBroker

  module Models

    class Webhook

      include Messages

      attr_accessor :id, :uuid, :consumer, :provider, :request

      def initialize attributes = {}
        @id = attributes[:id]
        @request = attributes[:request]
      end

      def validate
        messages = []
        messages << message('errors.validation.attribute_missing', attribute: 'request') unless request
        messages.concat request.validate if request
        messages
      end
    end

  end

end
