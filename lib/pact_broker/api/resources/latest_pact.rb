require 'pact_broker/api/resources/base_resource'

module PactBroker::Api

  module Resources

    class LatestPact < BaseResource

      def content_types_provided
        [["application/json", :to_json]]
      end

      def allowed_methods
        ["GET"]
      end

      def resource_exists?
        @pact = pact_service.find_pact(identifier_from_path.merge(:consumer_version_number => 'last'))
        @pact != nil
      end

      def to_json
        response.headers['X-Pact-Consumer-Version'] = @pact.consumer_version_number
        @pact.json_content
      end

    end
  end

end
