require 'pact_broker/api/resources/base_resource'

module PactBroker
  module Api
    module Resources
      class LatestPacts < BaseResource

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def to_json
          PactBroker::Api::Decorators::PactCollectionDecorator.new(pacts).to_json(user_options: { base_url: base_url })
        end

        def pacts
          pact_service.find_latest_pacts
        end
      end
    end
  end
end
