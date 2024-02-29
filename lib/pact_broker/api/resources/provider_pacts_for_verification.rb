require "pact_broker/api/resources/provider_pacts"
require "pact_broker/api/decorators/verifiable_pacts_decorator"
require "pact_broker/api/contracts/pacts_for_verification_query_string_schema"
require "pact_broker/api/decorators/pacts_for_verification_query_decorator"
require "pact_broker/api/contracts/pacts_for_verification_json_query_schema"
require "pact_broker/hash_refinements"

module PactBroker
  module Api
    module Resources
      class ProviderPactsForVerification < ProviderPacts
        using PactBroker::HashRefinements

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        # TODO drop support for GET in next major version.
        # GET was only used by the very first Ruby Pact clients that supported the 'pacts for verification'
        # feature, until it became clear that the parameters for the request were going to get nested and complex,
        # at which point the POST was added.
        def allowed_methods
          ["GET", "POST", "OPTIONS"]
        end

        def malformed_request?
          super || ((request.get? || (request.post? && content_type_json?)) && validation_errors_for_schema?(schema, query))
        end

        def process_post
          if content_type_json?
            response.body = to_json
            true
          else
            415
          end
        end

        # For this endoint, the POST is a "read" action (used for Pactflow)
        def read_methods
          super + %w{POST}
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
            **decorator_options(
              include_pending_status: parsed_query_params.include_pending_status,
              title: "Pacts to be verified by provider #{provider_name}",
              deprecated: request.get?
            )
          )
        end

        def schema
          if request.get?
            PactBroker::Api::Contracts::PactsForVerificationQueryStringSchema
          elsif request.post?
            PactBroker::Api::Contracts::PactsForVerificationJSONQuerySchema
          end
        end

        def parsed_query_params
          @parsed_query_params ||= decorator_class(:pacts_for_verification_query_decorator).new(OpenStruct.new).from_hash(query)
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
