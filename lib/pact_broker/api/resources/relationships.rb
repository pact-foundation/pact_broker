require "pact_broker/api/resources/base_resource"
require "pact_broker/api/decorators/relationships_csv_decorator"

module PactBroker
  module Api
    module Resources
      class Relationships < BaseResource
        def content_types_provided
          [["text/csv", :to_csv]]
        end

        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def to_csv
          decorator_class(:relationships_csv_decorator).new(pacts).to_csv
        end

        def pacts
          pact_service.find_latest_pacts
        end

        def policy_name
          :'integrations::integrations'
        end
      end
    end
  end
end
