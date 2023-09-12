require "pact_broker/api/resources/base_resource"

module PactBroker
  module Api
    module Resources
      class Branch < BaseResource
        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET", "DELETE", "OPTIONS"]
        end

        def resource_exists?
          !!branch
        end

        def to_json
          decorator_class(:branch_decorator).new(branch).to_json(**decorator_options)
        end

        def delete_resource
          branch_service.delete_branch(branch)
          true
        end

        def policy_name
          :'versions::branch'
        end

        private

        def branch
          @branch_version ||= branch_service.find_branch(**identifier_from_path.slice(:pacticipant_name, :branch_name))
        end
      end
    end
  end
end
