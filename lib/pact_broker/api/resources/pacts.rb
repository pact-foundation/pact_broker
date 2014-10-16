require 'pact_broker/api/resources/base_resource'
require 'pact_broker/pacts/pact_params'
require 'pact_broker/api/contracts/post_pact_params_contract'
require 'pact_broker/constants'

module PactBroker
  module Api
    module Resources

      class Pacts < BaseResource

        def content_types_accepted
          [["application/json", :from_json]]
        end

        def allowed_methods
          ["POST"]
        end

        def malformed_request?
          contract_validation_errors? Contracts::PostPactParamsContract.new(pact_params)
        end

        def post_is_create?
          true
        end

        def create_path
          pact_url_from_params base_url, pact_params
        end

        def from_json
          pact = pact_service.create_or_update_pact(pact_params)
          response.headers['Content-Type'] = "application/hal+json"
          response.body = decorate(pact).to_json(base_url: base_url)
        end

        def decorate pact
          PactBroker::Api::Decorators::PactDecorator.new(pact)
        end

        def pact_params
          @pact_params ||= PactBroker::Pacts::PactParams.from_post_request request
        end

      end
    end

  end
end