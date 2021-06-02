require "pact_broker/api/resources/base_resource"
require "pact_broker/api/decorators/versions_decorator"

module PactBroker
  module Api
    module Resources
      class DeployedVersionsForVersionAndEnvironment < BaseResource
        def initialize
          super
          @existing_deployed_version = version && environment && deployed_version_service.find_currently_deployed_version_for_version_and_environment_and_target(version, environment, target)
        end

        def content_types_accepted
          [["application/json", :from_json]]
        end

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET", "POST", "OPTIONS"]
        end

        def resource_exists?
          !!version && !!environment
        end

        def post_is_create?
          true
        end

        def create_path
          deployed_version_url(existing_deployed_version || OpenStruct.new(uuid: deployed_version_uuid), base_url)
        end

        def from_json
          @deployed_version = existing_deployed_version || deployed_version_service.create(deployed_version_uuid, version, environment, target)
          response.body = decorator_class(:deployed_version_decorator).new(deployed_version).to_json(decorator_options)
        end

        def to_json
          decorator_class(:deployed_versions_decorator).new(deployed_versions).to_json(decorator_options(title: title))
        end

        def policy_name
          :'versions::versions'
        end

        private

        attr_reader :deployed_version, :existing_deployed_version

        def version
          @version ||= version_service.find_by_pacticipant_name_and_number(identifier_from_path)
        end

        def environment
          @environment ||= environment_service.find(environment_uuid)
        end

        def deployed_versions
          @deployed_versions ||= deployed_version_service.find_deployed_versions_for_version_and_environment(version, environment)
        end

        def environment_uuid
          identifier_from_path[:environment_uuid]
        end

        def deployed_version_uuid
          @deployed_version_uuid ||= deployed_version_service.next_uuid
        end

        # TODO disallow an empty string because that is used as a NULL indicator in the database
        def target
          params(default: {})[:target]&.to_s
        end

        def title
          "Deployed versions for #{pacticipant_name} version #{pacticipant_version_number}"
        end
      end
    end
  end
end
