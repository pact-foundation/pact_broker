require 'pact_broker/api/resources/base_resource'
require 'pact_broker/configuration'
require 'pact_broker/domain/verification'
require 'pact_broker/api/contracts/verification_contract'
require 'pact_broker/api/decorators/verification_decorator'

module PactBroker
  module Api
    module Resources

      class Verifications < BaseResource

        def content_types_accepted
          [["application/json", :from_json]]
        end

        def allowed_methods
          ["POST"]
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
          verification = verification_service.create(next_verification_number, params_with_string_keys, pact)
          response.body = decorator_for(verification).to_json(user_options: {base_url: base_url})
          true
        end

        private

        def pact
          @pact ||= pact_service.find_pact(pact_params)
        end

        def next_verification_number
          @next_verification_number ||= verification_service.next_number_for(pact)
        end

        def decorator_for model
          PactBroker::Api::Decorators::VerificationDecorator.new(model)
        end

        def update_matrix_after_request?
          request.post?
        end
      end
    end
  end
end
