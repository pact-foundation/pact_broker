require 'pact_broker/api/resources/base_resource'
require 'pact_broker/configuration'
require 'pact_broker/domain/verification'
require 'pact_broker/api/contracts/verification_contract'
require 'pact_broker/api/decorators/verification_decorator'
require 'pact_broker/api/resources/webhook_execution_methods'

module PactBroker
  module Api
    module Resources
      class Verifications < BaseResource
        include WebhookExecutionMethods

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
          if request.post?
            return true if invalid_json?
            errors = verification_service.errors(params)
            if !errors.empty?
              set_json_validation_error_messages(errors.messages)
              return true
            end
          end
          false
        end

        def create_path
          new_verification_url(pact, next_verification_number, base_url)
        end

        def from_json
          verification = verification_service.create(next_verification_number, verification_params, pact, webhook_options)
          response.body = decorator_for(verification).to_json(decorator_options)
          true
        end

        def policy_name
          :'verifications::verifications'
        end

        def policy_pacticipant
          provider
        end

        private

        def pact
          @pact ||= pact_service.find_pact(pact_params)
        end

        def next_verification_number
          @next_verification_number ||= verification_service.next_number
        end

        def decorator_for model
          PactBroker::Api::Decorators::VerificationDecorator.new(model)
        end

        def metadata
          PactBrokerUrls.decode_pact_metadata(identifier_from_path[:metadata])
        end

        def wip?
          metadata[:wip] == 'true'
        end

        def webhook_options
          {
            database_connector: database_connector,
            webhook_execution_configuration: webhook_execution_configuration
                                      .with_webhook_context(metadata)
          }
        end

        def verification_params
          params(symbolize_names: false).merge('wip' => wip?)
        end
      end
    end
  end
end
