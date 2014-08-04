require 'pact_broker/models/webhook_request'

module PactBroker

  module Models

    class Webhook
      attr_accessor :id, :consumer_id, :provider_id, :request

      def initialize attributes = {}
        @id = attributes[:id]
        @request = attributes[:request]
      end
    end

  end

end
