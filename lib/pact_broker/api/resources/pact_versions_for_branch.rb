require "pact_broker/api/resources/base_resource"
require "pact_broker/configuration"
require "pact_broker/api/decorators/tagged_pact_versions_decorator"
require "pact_broker/api/resources/pact_resource_methods"

module PactBroker
  module Api
    module Resources
      class PactVersionsForBranch < BaseResource
        include PactResourceMethods

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET", "DELETE", "OPTIONS"]
        end

        def resource_exists?
          consumer && provider
        end

        def to_json
          decorator_class(:pact_versions_decorator).new(pacts).to_json(**decorator_options(identifier_from_path))
        end

        def pacts
          @pacts ||= pact_service.find_pacts_for_provider_and_consumer_by_consumer_branch(
            provider_name,
            consumer_name,
            branch_name: identifier_from_path[:branch_name],
            main_branch: identifier_from_path[:branch_name].nil?,
            latest: identifier_from_path[:resource_name] == "latest_pact_publications_for_main_branch" || identifier_from_path[:resource_name] == "latest_pact_publications_for_branch"
          )
        end

        def delete_resource
          pact_service.delete_all_pact_publications_between consumer_name, and: provider_name, branch_name: identifier_from_path[:branch_name]
          set_post_deletion_response
          true
        end

        def policy_name
          :'pacts::pact_versions'
        end
      end
    end
  end
end
