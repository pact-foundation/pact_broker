require 'cgi'
require 'pact_broker/api/resources/base_resource'

module PactBroker::Api

  module Resources

    class Pact < BaseResource

      def content_types_provided
        [["application/json", :to_json]]
      end

      def content_types_accepted
        [["application/json", :from_json]]
      end

      def allowed_methods
        ["GET", "PUT"]
      end

      def resource_exists?
        @pact = pact_service.find_pact(identifier_from_path)
        @pact != nil
      end

      def from_json
        pact, @created = pact_service.create_or_update_pact(identifier_from_path.merge(:json_content => pact_content))
        response.body = pact.json_content
      end

      def finish_request
        response.code = 201 if @created
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
