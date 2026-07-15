require "pact_broker/api/resources/base_resource"
require "pact_broker/api/decorators/versions_decorator"
require "pact_broker/api/resources/pagination_methods"

module PactBroker
  module Api
    module Resources
      class EnvironmentVersions < BaseResource
        include PaginationMethods

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def malformed_request?
          super || request.get? && validation_errors_for_schema?(schema, request.query)
        end

        def resource_exists?
          !!environment && !!pacticipant
        end

        def to_json
          decorator_class(:versions_decorator).new(versions).to_json(
            **decorator_options(
              resource_title: resource_title,
              deployed_versions: deployed_versions,
              released_versions: released_versions
            )
          )
        end

        def policy_name
          :'versions::versions'
        end

        private

        def versions
          @versions ||= version_service.find_by_ids_in_reverse_order(
            version_ids,
            pagination_options,
            decorator_class(:versions_decorator).eager_load_associations
          )
        end

        def version_ids
          deployed_ids = PactBroker::Deployments::DeployedVersion
            .for_environment(environment)
            .for_pacticipant_name(pacticipant_name)
            .select_map(:version_id)

          released_ids = PactBroker::Deployments::ReleasedVersion
            .for_environment(environment)
            .for_pacticipant_name(pacticipant_name)
            .select_map(:version_id)

          (deployed_ids + released_ids).uniq
        end

        def deployed_versions
          @deployed_versions ||= deployed_version_service.find_deployed_versions_for_versions(versions)
        end

        def released_versions
          @released_versions ||= released_version_service.find_released_versions_for_versions(versions)
        end

        def environment
          @environment ||= environment_service.find(identifier_from_path[:environment_uuid])
        end

        def resource_title
          "Versions for #{pacticipant.name} in environment #{environment.display_name}"
        end

        def schema
          PactBroker::Api::Contracts::PaginationQueryParamsSchema if request.get?
        end
      end
    end
  end
end
