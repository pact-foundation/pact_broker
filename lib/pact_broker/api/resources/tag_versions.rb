require "pact_broker/api/resources/base_resource"
require "pact_broker/api/decorators/versions_decorator"
require "pact_broker/api/resources/pagination_methods"

module PactBroker
  module Api
    module Resources
      class TagVersions < BaseResource
        include PactBroker::Api::Resources::PaginationMethods

        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def malformed_request?
          super || request.get? && validation_errors_for_schema?(schema, request.query)
        end

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def policy_name
          :'versions::versions'
        end

        def resource_exists?
          !tags.empty?
        end

        def to_json
          decorator_class(:versions_decorator).new(tag_versions)
            .to_json(**decorator_options(deployed_versions: deployed_versions))
        end

        private

        def deployed_versions
          @deployed_versions ||= deployed_version_service.find_deployed_versions_for_versions(tag_versions)
        end

        def tag_versions
          @versions ||= version_service.find_by_ids_in_reverse_order(@tags.select_map(:version_id), pagination_options, decorator_class(:versions_decorator).eager_load_associations)
        end

        def tags
          @tags ||= tag_service.find_all_by_pacticipant_name_and_tag(**identifier_from_path.slice(:pacticipant_name, :tag_name))
        end

        def schema
          if request.get?
            PactBroker::Api::Contracts::PaginationQueryParamsSchema
          end
        end
      end
    end
  end
end
