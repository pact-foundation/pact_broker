require 'pact_broker/api/resources/provider_pacts'
require 'pact_broker/api/decorators/verifiable_pacts_decorator'
require 'pact_broker/api/contracts/verifiable_pacts_query_schema'
require 'pact_broker/api/decorators/verifiable_pacts_query_decorator'

module PactBroker
  module Api
    module Resources
      class ProviderPactsForVerification < ProviderPacts
        def initialize
          @query = Rack::Utils.parse_nested_query(request.uri.query)
        end

        def malformed_request?
          if (errors = query_schema.call(query)).any?
            set_json_validation_error_messages(errors)
            true
          else
            false
          end
        end

        private

        def pacts
          pact_service.find_for_verification(
            provider_name,
            parsed_query_params.provider_version_tags,
            parsed_query_params.consumer_version_selectors
          )
        end

        def resource_title
          "Pacts to be verified by provider #{provider_name}"
        end

        def to_json
          PactBroker::Api::Decorators::VerifiablePactsDecorator.new(pacts).to_json(to_json_options)
        end

        private

        attr_reader :query

        def query_schema
          PactBroker::Api::Contracts::VerifiablePactsQuerySchema
        end

        def parsed_query_params
          @parsed_query_params ||= PactBroker::Api::Decorators::VerifiablePactsQueryDecorator.new(OpenStruct.new).from_hash(query)
        end
      end
    end
  end
end
