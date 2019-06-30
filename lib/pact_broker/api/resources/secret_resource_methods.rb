require 'pact_broker/api/contracts/secret_contract'
require 'pact_broker/api/decorators/secret_decorator'
require 'pact_broker/secrets/unencrypted_secret'

module PactBroker
  module Api
    module Resources
      module SecretResourceMethods
        def malformed_request?
          if request.post? || request.put?
            return invalid_json? || contract_validation_errors?(contract, params)
          end
          false
        end

        def is_conflict?
          if (unconfigured = !secret_service.encryption_key_configured?(secrets_encryption_key_id))
            set_json_error_message(message: message('errors.encryption_key_not_configured'))
          end
          unconfigured
        end

        def unencrypted_secret_from_request
          Decorators::SecretDecorator.new(PactBroker::Secrets::UnencryptedSecret.new).from_json(request_body)
        end

        def contract
          Contracts::SecretContract.new
        end

        def secret_to_json(secret)
          Decorators::SecretDecorator.new(secret).to_json(user_options: decorator_context)
        end

        def secrets_encryption_key_id
          request.env["pactbroker.secrets_encryption_key_id"]
        end
      end
    end
  end
end
