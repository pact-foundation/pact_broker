require "pact_broker/api/resources/base_resource"
require "pact_broker/configuration"
require "pact_broker/api/decorators/provider_pacts_decorator"

module PactBroker
  module Api
    module Resources
      class ProviderPactsForConsumerBranch < BaseResource

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def resource_exists?
          !!provider
        end

        def policy_name
          :'pacts::provider_pacts'
        end

        def to_json
          decorator_class(:provider_pacts_decorator).new(pacts).to_json(**decorator_options(identifier_from_path.merge(title: resource_title)))
        end

        private

        def pacts
          pact_service.find_pacts_for_provider_by_consumer_branch(
          provider_name, 
          branch_name: identifier_from_path[:branch_name], 
          main_branch: identifier_from_path[:branch_name] ? false : true
          )
        end

        def resource_title
          suffix = identifier_from_path[:branch_name] ? " with consumer version branch '#{identifier_from_path[:branch_name]}'" : ""
          "All pact versions for the provider #{identifier_from_path[:provider_name]}#{suffix}"
        end
      end
    end
  end
end
