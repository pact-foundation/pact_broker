require "pact_broker/api/resources/provider_pacts"
require "pact_broker/api/decorators/verifiable_pacts_decorator"
require "pact_broker/api/contracts/verifiable_pacts_query_schema"
require "pact_broker/api/decorators/verifiable_pacts_query_decorator"
require "pact_broker/api/contracts/verifiable_pacts_json_query_schema"
require "pact_broker/hash_refinements"

module PactBroker
  module Api
    module Resources
      class ProviderPactsForVerification < ProviderPacts
        using PactBroker::HashRefinements

        def allowed_methods
          ["GET", "POST", "OPTIONS"]
        end

        def content_types_accepted
          [["application/json"]]
        end

        def malformed_request?
          if (errors = query_schema.call(query)).any?
            set_json_validation_error_messages(errors)
            true
          else
            false
          end
        end

        def process_post
          response.body = to_json
          true
        end

        private

        def pacts
          @pacts ||= pact_service.find_for_verification(
            provider_name,
            parsed_query_params.provider_version_branch,
            parsed_query_params.provider_version_tags,
            parsed_query_params.consumer_version_selectors,
            {
              include_wip_pacts_since: parsed_query_params.include_wip_pacts_since,
              include_pending_status: parsed_query_params.include_pending_status
            }
          )
        end

        def resource_title
          "Pacts to be verified by provider #{provider_name}"
        end

        def to_json
          log_request
          decorator_class(:verifiable_pacts_decorator).new(pacts).to_json(
            decorator_options(
              include_pending_status: parsed_query_params.include_pending_status,
              title: "Pacts to be verified by provider #{provider_name}",
              deprecated: request.get?
            )
          )
        end

        def query_schema
          if request.get?
            PactBroker::Api::Contracts::VerifiablePactsQuerySchema
          else
            PactBroker::Api::Contracts::VerifiablePactsJSONQuerySchema
          end
        end

        def parsed_query_params
          @parsed_query_params ||= decorator_class(:verifiable_pacts_query_decorator).new(OpenStruct.new).from_hash(query)
        end

        def query
          @query ||= begin
            if request.get?
              nested_query
            elsif request.post?
              params(symbolize_names: false, default: {})
            end
          end
        end

        def log_request
          logger.info "Fetching pacts for verification by #{provider_name}", provider_name: provider_name, params: query
        end

        def nested_query
          @nested_query ||= Rack::Utils.parse_nested_query(request.uri.query)
        end
      end
    end
  end
end
