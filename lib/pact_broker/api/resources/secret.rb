require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/decorators/secrets_decorator'
require 'pact_broker/api/decorators/secret_decorator'
require 'pact_broker/api/contracts/secret_contract'
require 'pact_broker/secrets/unencrypted_secret'

module PactBroker
  module Api
    module Resources
      class Secret < BaseResource
        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def content_types_accepted
          [["application/json"]]
        end

        def allowed_methods
          ["DELETE", "OPTIONS"]
        end

        def resource_exists?
          !!unencrypted_secret
        end

        def delete_resource
          secret_service.delete_by_uuid(uuid)
          true
        end

        private

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
