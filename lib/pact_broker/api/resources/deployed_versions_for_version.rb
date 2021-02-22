require 'pact_broker/api/resources/base_resource'
require 'pact_broker/configuration'
require 'pact_broker/api/decorators/versions_decorator'

module PactBroker
  module Api
    module Resources
      class DeployedVersionsForVersion < BaseResource
        def content_types_accepted
          [["application/json", :from_json]]
        end

        def content_types_provided
          [["application/hal+json"]]
        end

        def allowed_methods
          ["POST", "OPTIONS"]
        end

        def resource_exists?
          !!version && !!environment
        end

        def post_is_create?
          true
        end

        def create_path
          deployed_version_url(OpenStruct.new(uuid: deployed_version_uuid), base_url)
        end

        def from_json
          @deployed_version = deployed_version_service.create(deployed_version_uuid, version, environment, replaced_previous_deployed_version)
          response.body = to_json
        end

        def to_json
          decorator_class(:deployed_version_decorator).new(deployed_version).to_json(decorator_options)
        end

        def policy_name
          :'versions::versions'
        end

        private

        attr_reader :deployed_version

        def version
          @version ||= version_service.find_by_pacticipant_name_and_number(identifier_from_path)
        end

        def environment
          @environment ||= environment_service.find(environment_uuid)
        end

        def environment_uuid
          identifier_from_path[:environment_uuid]
        end

        def deployed_version_uuid
          @deployed_version_uuid ||= deployed_version_service.next_uuid
        end

        def replaced_previous_deployed_version
          params[:replacedPreviousDeployedVersion] == true
        end
      end
    end
  end
end
