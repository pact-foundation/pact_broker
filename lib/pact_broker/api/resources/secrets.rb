require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/decorators/secrets_decorator'
require 'pact_broker/api/decorators/secret_decorator'
require 'pact_broker/api/contracts/secret_contract'
require 'pact_broker/secrets/unencrypted_secret'

module PactBroker
  module Api
    module Resources
      class Secrets < BaseResource
        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def content_types_accepted
          [["application/json", :from_json]]
        end

        def allowed_methods
          ["GET", "POST", "OPTIONS"]
        end

        def malformed_request?
          if request.post?
            return invalid_json? || contract_validation_errors?(contract, params)
          end
          false
        end

        # Lifecycle method not actually called for POST, so call it manually
        def is_conflict?
          !secret_service.encryption_key_configured?(secrets_encryption_key_id)
        end

        def post_is_create?
          true
        end

        def from_json
          if is_conflict?
            set_json_error_message(message('errors.encryption_key_not_configured'))
            409
          else
            create_secret
          end
        end

        def create_path
          "/secrets/#{next_uuid}"
        end

        def to_json

        end

        private

        def create_secret
          unencrypted_secret = Decorators::SecretDecorator.new(PactBroker::Secrets::UnencryptedSecret.new).from_json(params)
          created_unencrypted_secret = secret_service.create(next_uuid, unencrypted_secret, secrets_encryption_key_id)
          response.body = Decorators::SecretDecorator.new(created_unencrypted_secret).to_json(user_options: { base_url: base_url })
        end

        def contract
          Contracts::SecretContract.new
        end

        def next_uuid
          @next_uuid ||= secret_service.next_uuid
        end

        def secrets_encryption_key_id
          request.env["pactbroker.secrets_encryption_key_id"]
        end
      end
    end
  end
end
