require 'pact_broker/models/webhook_request'
require 'pact_broker/messages'

module PactBroker

  module Models

    class Webhook

      include Messages

      attr_accessor :id, :consumer_id, :provider_id, :request

      def initialize attributes = {}
        @id = attributes[:id]
        @request = attributes[:request]
      end

      def validate
        [message('errors.validation.attribute_missing', attribute: 'method')]
      end
    end

  end

end
