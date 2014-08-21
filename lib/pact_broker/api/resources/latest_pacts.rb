require 'pact_broker/api/resources/base_resource'

module PactBroker
  module Api
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
          PactBroker::Api::Decorators::PactCollectionDecorator.new(pacts).to_json(base_url: base_url)
        end

      end
    end

  end
end