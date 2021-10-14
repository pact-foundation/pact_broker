require "pact_broker/api/resources/base_resource"
require "pact_broker/api/decorators/versions_decorator"
require "pact_broker/string_refinements"

module PactBroker
  module Api
    module Resources
      class CurrentlyDeployedVersionsForEnvironment < BaseResource
        using PactBroker::StringRefinements

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
          decorator_class(decorator_name).new(deployed_versions).to_json(decorator_options(title: title))
        end

        def policy_name
          :'deployments::environment'
        end

        def policy_record
          environment
        end

        def decorator_name
          :deployed_versions_decorator
        end

        private

        def environment
          @environment ||= environment_service.find(environment_uuid)
        end

        def deployed_versions
          @deployed_versions ||= deployed_version_service.find_currently_deployed_versions_for_environment(environment, query_params)
        end

        def environment_uuid
          identifier_from_path[:environment_uuid]
        end

        def query_params
          # Webmachine request.query drops parameters with blank values, and we need to know if
          # a blank target was specified.
          query = Rack::Utils.parse_query(request.env["QUERY_STRING"])
          q = {}
          q[:pacticipant_name] = request.query["pacticipant"] if query["pacticipant"]
          if query["applicationInstance"]
            q[:target] = query["applicationInstance"].blank? ? nil : query["applicationInstance"]
          elsif query["target"]
            q[:target] = query["target"].blank? ? nil : query["target"]
          end
          q
        end

        def title
          "Currently deployed versions for #{environment.display_name}"
        end
      end
    end
  end
end
