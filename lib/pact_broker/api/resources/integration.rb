require 'pact_broker/api/resources/base_resource'

module PactBroker
  module Api
    module Resources
      class Integration < BaseResource
        def allowed_methods
          ["OPTIONS", "DELETE"]
        end

        def resource_exists?
          consumer && provider
        end

        def delete_resource
          integration_service.delete(consumer_name, provider_name)
          true
        end

        def policy_name
          :'integrations::integration'
        end

        def policy_resource
          integration
        end

        def integration
          @integration ||= OpenStruct.new(consumer: consumer, provider: provider)
        end
      end
    end
  end
end
