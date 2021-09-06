require "pact_broker/api/resources/base_resource"
require "pact_broker/api/decorators/branch_version_decorator"

module PactBroker
  module Api
    module Resources
      class BranchVersion < BaseResource
        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def content_types_accepted
          [["application/json", :from_json]]
        end

        def allowed_methods
          ["GET", "PUT", "OPTIONS"]
        end

        def resource_exists?
          !!branch_version
        end

        def to_json
          decorator_class(:branch_version_decorator).new(branch_version).to_json(decorator_options)
        end

        def from_json
          already_existed = !!branch_version
          @branch_version = branch_service.find_or_create_branch_version(identifier_from_path)
          # Make it return a 201 by setting the Location header
          response.headers["Location"] = branch_version_url(branch_version, base_url) unless already_existed
          response.body = to_json
        end

        def policy_name
          :'versions::branch_version'
        end

        private

        def branch_version
          @branch_version ||= branch_service.find_branch_version(identifier_from_path)
        end
      end
    end
  end
end
