require "pact_broker/api/resources/base_resource"
require "pact_broker/api/decorators/versions_decorator"
require "pact_broker/string_refinements"

module PactBroker
  module Api
    module Resources
      class CurrentlySupportedVersionsForEnvironment < BaseResource
        using PactBroker::StringRefinements

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
          decorator_class(decorator_name).new(released_versions).to_json(**decorator_options(title: title, expand: [:pacticipant, :version]))
        end

        def policy_name
          :'deployments::environment'
        end

        def policy_record
          environment
        end

        def decorator_name
          :released_versions_decorator
        end

        private

        def environment
          @environment ||= environment_service.find(environment_uuid)
        end

        def released_versions
          @released_versions ||= released_version_service.find_currently_supported_versions_for_environment(environment, **query_params)
        end

        def environment_uuid
          identifier_from_path[:environment_uuid]
        end

        def query_params
          {
            pacticipant_name: request.query["pacticipant"],
            pacticipant_version_number: request.query["version"]
          }.compact
        end

        def title
          "Currently supported versions in #{environment.display_name}"
        end
      end
    end
  end
end
