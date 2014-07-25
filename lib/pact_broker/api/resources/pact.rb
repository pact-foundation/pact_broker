require 'cgi'
require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/decorators/pact_decorator'

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
        @pact, created = pact_service.create_or_update_pact(identifier_from_path.merge(:json_content => pact_content))
        response.headers["Location"] = pact_url(resource_url, @pact) if created
        response.body = to_json
      end

      def to_json
        PactBroker::Api::Decorators::PactDecorator.new(@pact).to_json
      end

      def pact_content
        request.body.to_s
      end

    end
  end

end
