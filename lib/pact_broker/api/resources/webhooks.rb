require 'pact_broker/api/resources/base_resource'

module PactBroker::Api

  module Resources

    class Webhooks < BaseResource

      def content_types_accepted
        [["application/json", :from_json]]
      end

      def allowed_methods
        ["POST"]
      end

      def from_json

      end

    end
  end

end
