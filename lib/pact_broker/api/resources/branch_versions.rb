require "pact_broker/api/resources/base_resource"
require "pact_broker/configuration"
require "pact_broker/api/decorators/versions_decorator"
require "pact_broker/api/resources/pagination_methods"


module PactBroker
  module Api
    module Resources
      class BranchVersions < BaseResource
        include PaginationMethods

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def resource_exists?
          !!branch
        end

        def to_json
          decorator_class(:versions_decorator).new(versions).to_json(**decorator_options(identifier_from_path.merge(resource_title: resource_title)))
        end

        def versions
          @versions ||= version_service.find_pacticipant_versions_in_reverse_order(pacticipant_name, { branch_name: identifier_from_path[:branch_name] }, pagination_options)
        end

        def policy_name
          :'versions::versions'
        end

        def branch
          @branch ||= branch_service.find_branch(**identifier_from_path.slice(:pacticipant_name, :branch_name))
        end

        def resource_title
          "Versions for branch #{branch.name} of #{branch.pacticipant.name}"
        end
      end
    end
  end
end
