require 'pact_broker/api/resources/provider_pacts'
require 'pact_broker/api/decorators/verifiable_pacts_decorator'
require 'pact_broker/api/contracts/verifiable_pacts_query_schema'
require 'pact_broker/api/decorators/verifiable_pacts_query_decorator'
require 'pact_broker/api/contracts/verifiable_pacts_json_query_schema'
require 'pact_broker/hash_refinements'

module PactBroker
  module Api
    module Resources
      class AggregatedPactForVerification < BaseResource
        using PactBroker::HashRefinements

        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def content_types_provided
          [["application/hal+json", :to_json]]
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
          pact_service.aggregate_pacts(pacts, provider_name).merge(_links).to_json
        end

        def _links
          {
            "_links" => {
              "pb:publish-verification-results" => {
                "href" => resource_url + "/verifications"
              }
            }
          }

        end

        def query_schema
          PactBroker::Api::Contracts::VerifiablePactsJSONQuerySchema
        end

        def parsed_query_params
          @parsed_query_params ||= decorator_class(:verifiable_pacts_query_decorator).new(OpenStruct.new).from_hash(query)
        end

        def query
          @query ||= JSON.parse(decode_pact_metadata(identifier_from_path[:query]).to_json.gsub('"true"', "true")).tap { |it| puts it }
        end
      end
    end
  end
end
