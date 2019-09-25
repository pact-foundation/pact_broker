require 'pact_broker/api/resources/base_resource'

module PactBroker
  module Api
    module Resources
      class Metrics < BaseResource
        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def to_json
          metrics_service.metrics.to_json
        end
      end
    end
  end
end
