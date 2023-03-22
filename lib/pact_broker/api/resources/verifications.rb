require "pact_broker/api/resources/base_resource"
require "pact_broker/configuration"
require "pact_broker/domain/verification"
require "pact_broker/api/contracts/verification_contract"
require "pact_broker/api/decorators/verification_decorator"
require "pact_broker/api/resources/webhook_execution_methods"
require "pact_broker/api/resources/metadata_resource_methods"

module PactBroker
  module Api
    module Resources
      class Verifications < BaseResource
        include WebhookExecutionMethods
        include MetadataResourceMethods

        def content_types_accepted
          [["application/json", :from_json]]
        end

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["POST", "OPTIONS"]
        end

        def post_is_create?
          true
        end

        def resource_exists?
          !!pact
        end

        def malformed_request?
          super || (request.post? && validation_errors_for_schema?)
        end

        def create_path
          new_verification_url(pact, next_verification_number, base_url)
        end

        def from_json
          handle_webhook_events(build_url: verification_params["buildUrl"]) do
            verified_pacts = pact_service.find_for_verification_publication(pact_params, event_context[:consumer_version_selectors])
            verification = verification_service.create(next_verification_number, verification_params, verified_pacts, event_context)
            response.body = decorator_for(verification).to_json(**decorator_options)
          end
          true
        end

        def policy_name
          :'verifications::verifications'
        end

        private

        def pact
          @pact ||= pact_service.find_pact(pact_params)
        end

        def next_verification_number
          @next_verification_number ||= verification_service.next_number
        end

        def decorator_for model
          decorator_class(:verification_decorator).new(model)
        end

        def wip?
          metadata[:wip] == "true"
        end

        def pending?
          metadata[:pending]
        end

        def event_context
          metadata
        end

        def verification_params
          params(symbolize_names: false).merge("wip" => wip?, "pending" => pending?)
        end

        def schema
          PactBroker::Api::Contracts::VerificationContract
        end
      end
    end
  end
end
