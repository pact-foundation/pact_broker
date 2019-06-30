require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/decorators/secrets_decorator'
require 'pact_broker/api/decorators/secret_decorator'
require 'pact_broker/api/resources/secret_resource_methods'

module PactBroker
  module Api
    module Resources
      class Secrets < BaseResource
        include SecretResourceMethods

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def content_types_accepted
          [["application/json", :from_json]]
        end

        def allowed_methods
          ["GET", "POST", "OPTIONS"]
        end

        def post_is_create?
          true
        end

        def from_json
          # Lifecycle method not actually called for POST, so call it manually
          if is_conflict?
            409
          else
            create_secret
          end
        end

        def create_path
          "/secrets/#{next_uuid}"
        end

        def to_json
          Decorators::SecretsDecorator.new(secret_service.find_all).to_json(user_options: decorator_context)
        end

        private

        def create_secret
          created_unencrypted_secret = secret_service.create(next_uuid, unencrypted_secret_from_request, secrets_encryption_key_id)
          response.body = secret_to_json(created_unencrypted_secret)
        end

        def next_uuid
          @next_uuid ||= secret_service.next_uuid
        end
      end
    end
  end
end
