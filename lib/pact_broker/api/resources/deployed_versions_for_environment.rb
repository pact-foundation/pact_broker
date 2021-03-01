require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/decorators/versions_decorator'

module PactBroker
  module Api
    module Resources
      class DeployedVersionsForEnvironment < BaseResource
        def content_types_accepted
          [["application/json", :from_json]]
        end

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def resource_exists?
          !!environment
        end

        def to_json
          decorator_class(:deployed_versions_decorator).new(deployed_versions).to_json(decorator_options(title: title))
        end

        def policy_name
          :'versions::versions'
        end

        private

        attr_reader :deployed_versions

        def environment
          @environment ||= environment_service.find(environment_uuid)
        end

        def deployed_versions
          @deployed_versions ||= deployed_version_service.find_deployed_versions_for_environment(environment)
        end

        def environment_uuid
          identifier_from_path[:environment_uuid]
        end

        def title
          "Deployed versions for #{environment.display_name}"
        end
      end
    end
  end
end
