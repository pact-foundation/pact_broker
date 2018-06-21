require 'pact_broker/api/resources/base_resource'
require 'pact_broker/error'

module PactBroker
  module Api
    module Resources

      class ErrorTest < BaseResource

        def content_types_provided
          [
            ["application/hal+json", :to_json]
          ]
        end

        def content_types_accepted
          [
            ["application/hal+json", :from_json]
          ]
        end

        def allowed_methods
          ["GET", "POST", "OPTIONS"]
        end

        def to_json
          raise PactBroker::TestError.new("Don't panic. This is a test API error.")
        end

        def from_json
          raise PactBroker::TestError.new("Don't panic. This is a test API error.")
        end
      end
    end
  end
end
