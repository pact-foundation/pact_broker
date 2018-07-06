require 'pact_broker/api/resources/provider_pacts'
require 'pact_broker/configuration'
require 'pact_broker/api/decorators/provider_pacts_decorator'

module PactBroker
  module Api
    module Resources
      class WipProviderPacts < ProviderPacts
        private

        def pacts
          pact_service.find_wip_pact_versions_for_provider provider_name
        end

        def resource_title
          "WIP pact versions for the provider #{provider_name}"
        end
      end
    end
  end
end
