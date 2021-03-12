require 'pact_broker/api/resources/base_resource'
require 'pact_broker/configuration'
require 'pact_broker/domain/verification'
require 'pact_broker/api/contracts/verification_contract'
require 'pact_broker/api/decorators/verification_decorator'
require 'pact_broker/api/resources/webhook_execution_methods'
require 'pact_broker/api/resources/metadata_resource_methods'

module PactBroker
  module Api
    module Resources
      class AggregatedVerifications < BaseResource
        include WebhookExecutionMethods
        include MetadataResourceMethods

        def content_types_accepted
          [["application/json", :from_json]]
        end

        def content_types_provided
          [["application/hal+json"]]
        end

        def allowed_methods
          ["POST", "OPTIONS"]
        end

        def post_is_create?
          true
        end

        def resource_exists?
          !!provider
        end

        def malformed_request?
          # if request.post?
          #   return true if invalid_json?
          #   errors = verification_service.errors(params)
          #   if !errors.empty?
          #     set_json_validation_error_messages(errors.messages)
          #     return true
          #   end
          # end
          # false
        end

        def create_path
          "dummy"
        end

        def from_json
          verifications = pacts.collect do | pact |
            verification_service.create(verification_service.next_number, verification_params, pact, event_context, webhook_options)
          end
          response.headers["Location"] = verification_url(verifications.last, base_url)
          response.body = decorator_class(:verification_decorator).new(verifications.last).to_json(decorator_options)
          true
        end

        def policy_name
          :'verifications::verifications'
        end

        def policy_pacticipant
          provider
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

        def query_schema
          PactBroker::Api::Contracts::VerifiablePactsJSONQuerySchema
        end

        def parsed_query_params
          @parsed_query_params ||= decorator_class(:verifiable_pacts_query_decorator).new(OpenStruct.new).from_hash(query)
        end

        def query
          @query ||= JSON.parse(decode_pact_metadata(identifier_from_path[:query]).to_json.gsub('"true"', "true")).tap { |it| puts it }
        end


        # def decorator_for model
        #   decorator_class(:verification_decorator).new(model)
        # end

        def wip?
          # metadata[:wip] == 'true'
          false
        end

        def event_context
          {}
        end

        def webhook_options
          {
            database_connector: database_connector,
            webhook_execution_configuration: webhook_execution_configuration
          }
        end

        def verification_params
          params(symbolize_names: false).merge('wip' => wip?)
        end
      end
    end
  end
end
