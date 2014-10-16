require 'pact_broker/api/resources/base_resource'
require 'pact_broker/pacts/pact_params'
require 'pact_broker/api/contracts/create_pact_request_contract'
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
          contract_validation_errors? Contracts::CreatePactRequestContract.new(request)
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

        def pact_params
          {
            consumer_name: consumer_name,
            consumer_version_number: consumer_version_number,
            provider_name: provider_name,
            json_content: request_body
          }
        end

        def consumer_version_number
          request.headers[CONSUMER_VERSION_HEADER]
        end

        # Naughty inspecting the Pact content directly...
        def consumer_name
          params[:consumer][:name]
        end

        def provider_name
          params[:provider][:name]
        end

        def decorate pact
          PactBroker::Api::Decorators::PactDecorator.new(pact)
        end

      end
    end

  end
end