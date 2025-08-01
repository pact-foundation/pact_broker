require "pact_broker/api/resources/base_resource"
require "pact_broker/api/decorators/provider_states_decorator"

module PactBroker
  module Api
    module Resources
      class ProviderStates < BaseResource
        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def resource_exists?
          !!provider
        end

        def to_json
          decorator_class(:provider_states_decorator).new(provider_states).to_json(decorator_options)
        end

        def policy_name
          :'pacts::pact'
        end

        def environment_uuid
          identifier_from_path[:environment_uuid]
        end

        def branch_name
          identifier_from_path[:branch_name]
        end

        private

        def provider_states
          @provider_states ||= provider_state_service.list_provider_states(provider, branch_name, environment_uuid)
        end
      end
    end
  end
end