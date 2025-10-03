require "pact_broker/api/resources/provider_pacts"
require "pact_broker/configuration"
require "pact_broker/api/decorators/provider_pacts_decorator"

module PactBroker
  module Api
    module Resources
      class LatestProviderPactsForBranch < ProviderPacts
        private

        def pacts
          pact_service.find_latest_pacts_for_provider_by_consumer_branch(
          provider_name, 
          branch_name: identifier_from_path[:branch_name], 
          main_branch: identifier_from_path[:branch_name] ? false : true
          )
        end

        def resource_title
          suffix = identifier_from_path[:branch_name] ? " with consumer version branch '#{identifier_from_path[:branch_name]}'" : ""
          "Latest pact versions for the provider #{identifier_from_path[:provider_name]}#{suffix}"
        end
      end
    end
  end
end
