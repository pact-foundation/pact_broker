require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/decorators/secret_decorator'
require 'pact_broker/api/resources/secret_resource_methods'

module PactBroker
  module Api
    module Resources
      class Secret < BaseResource
        include SecretResourceMethods

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def content_types_accepted
          [["application/json", :from_json]]
        end

        def allowed_methods
          ["PUT", "DELETE", "OPTIONS"]
        end

        def resource_exists?
          !!unencrypted_secret
        end

        def delete_resource
          secret_service.delete_by_uuid(uuid)
          true
        end

        private

        def from_json
          created_unencrypted_secret = secret_service.update(uuid, unencrypted_secret_from_request, secrets_encryption_key_id)
          response.body = secret_to_json(created_unencrypted_secret)
        end

        def unencrypted_secret
          @unencrypted_secret ||= secret_service.find_by_uuid(uuid)
        end

        def uuid
          identifier_from_path[:uuid]
        end
      end
    end
  end
end
