require "pact_broker/api/resources/provider_pacts"
require "pact_broker/configuration"
require "pact_broker/api/decorators/provider_pacts_decorator"

module PactBroker
  module Api
    module Resources
      class LatestProviderPacts < ProviderPacts
        private

        def pacts
          pact_service.find_latest_pact_versions_for_provider provider_name, tag: identifier_from_path[:tag]
        end

        def resource_title
          suffix = identifier_from_path[:tag] ? " with consumer version tag '#{identifier_from_path[:tag]}'" : ""
          "Latest pact versions for the provider #{identifier_from_path[:provider_name]}#{suffix}"
        end
      end
    end
  end
end
