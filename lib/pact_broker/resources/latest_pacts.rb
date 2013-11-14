require 'pact_broker/resources/base_resource'

module PactBroker

  module Resources

    class LatestPacts < BaseResource

      def content_types_provided
        [["application/hal+json", :to_json]]
      end

      def allowed_methods
        ["GET"]
      end

      def to_json
        generate_json(pact_service.find_latest_pacts)
      end

      def generate_json pacts
        PactBroker::Api::Decorators::PactCollectionRepresenter.new(pacts, request_base_url).to_json
      end

    end
  end

end
