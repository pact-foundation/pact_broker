require "pact_broker/api/resources/base_resource"
require "pact_broker/pacts/pact_params"
require "pact_broker/pacts/diff"
require "pact_broker/api/decorators/pact_decorator"

module PactBroker
  module Api
    module Resources
      class PreviousDistinctPactVersion < BaseResource

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def resource_exists?
          !!pact
        end

        def to_json
          decorator_class(:pact_decorator).new(pact).to_json(**decorator_options)
        end

        def pact
          @pact ||= pact_service.find_previous_distinct_pact_version(pact_params)
        end

        def pact_params
          @pact_params ||= PactBroker::Pacts::PactParams.from_request request, identifier_from_path
        end

        def policy_name
          :'pacts::pact'
        end
      end
    end
  end
end
