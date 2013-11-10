require 'webmachine'
require 'json'

require 'pact_broker/services'
require 'pact_broker/resources/json_resource'

module PactBroker

  module Resources

    class LatestPact < Webmachine::Resource

      include PactBroker::Services
      include PactBroker::Resources::PathInfo

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

      def handle_exception e
        PactBroker::Resources::ErrorHandler.handle_exception(e, response)
      end

    end
  end

end
