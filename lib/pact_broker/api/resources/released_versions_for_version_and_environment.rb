require "pact_broker/api/resources/base_resource"
require "pact_broker/api/decorators/versions_decorator"

module PactBroker
  module Api
    module Resources
      class ReleasedVersionsForVersionAndEnvironment < BaseResource
        def initialize
          super
          @existing_released_version = version && environment && released_version_service.find_released_version_for_version_and_environment(version, environment)
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
          released_version_url(existing_released_version || OpenStruct.new(uuid: next_released_version_uuid), base_url)
        end

        def from_json
          @released_version = released_version_service.create_or_update(next_released_version_uuid, version, environment)
          response.body = decorator_class(:released_version_decorator).new(released_version).to_json(decorator_options)
          true
        end

        def to_json
          decorator_class(:released_versions_decorator).new(released_versions).to_json(decorator_options(title: title))
        end

        def policy_name
          :'versions::released_versions'
        end

        def policy_record
          environment
        end

        def finish_request
          if request.post? && existing_released_version
            response.code = 200
          end
          super
        end

        private

        attr_reader :released_version, :existing_released_version

        def version
          @version ||= version_service.find_by_pacticipant_name_and_number(identifier_from_path)
        end

        def environment
          @environment ||= environment_service.find(environment_uuid)
        end

        def released_versions
          @released_versions ||= begin
            if existing_released_version
              [existing_released_version]
            else
              []
            end
          end
        end

        def environment_uuid
          identifier_from_path[:environment_uuid]
        end

        def next_released_version_uuid
          @released_version_uuid ||= released_version_service.next_uuid
        end

        def title
          "Released versions for #{pacticipant.display_name} version #{pacticipant_version_number} in #{environment.display_name}"
        end
      end
    end
  end
end
