require 'pact_broker/api/resources/base_resource'

module PactBroker
  module Api
    module Resources

      class Dashboard < BaseResource

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET"]
        end

        def to_json

        end
      end
    end
  end
end
