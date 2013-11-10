require 'webmachine'
require 'json'
require 'cgi'

require 'pact_broker/services'
require 'pact_broker/resources/json_resource'

module PactBroker

  module Resources

    class Pact < JsonResource

      include PactBroker::Services
      include PactBroker::Resources::PathInfo

      def allowed_methods
        ["GET", "PUT"]
      end

      def resource_exists?
        @pact = pact_service.find_pact(identifier_from_path)
        @pact != nil
      end

      def from_json
        pact, created = pact_service.create_or_update_pact(identifier_from_path.merge(:json_content => pact_content))
        response.body = pact.json_content
        @manual_response_code = 201 if created
      end

      def finish_request
        if @manual_response_code
          response.code = @manual_response_code
        end
      end

      def to_json
        @pact.json_content
      end

      def pact_content
        request.body.to_s
      end

    end
  end

end
