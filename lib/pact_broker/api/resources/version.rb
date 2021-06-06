require "pact_broker/services"
require "pact_broker/api/decorators/version_decorator"
require "pact_broker/api/resources/base_resource"

module PactBroker
  module Api
    module Resources
      class Version < BaseResource
        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def content_types_accepted
          [
            ["application/json", :from_json],
            ["application/merge-patch+json", :from_merge_patch_json]
          ]
        end

        def allowed_methods
          ["GET", "PUT", "PATCH", "DELETE", "OPTIONS"]
        end

        def is_conflict?
          if (errors = version_service.conflict_errors(version, parsed_version, resource_url)).any?
            set_json_validation_error_messages(errors)
          else
            false
          end
        end

        def resource_exists?
          !!version
        end

        def from_json
          if request.really_put?
            handle_request do
              version_service.create_or_overwrite(pacticipant_name, pacticipant_version_number, parsed_version)
            end
          else
            415
          end
        end

        def from_merge_patch_json
          if request.patch?
            handle_request do
              version_service.create_or_update(pacticipant_name, pacticipant_version_number, parsed_version)
            end
          else
            415
          end
        end

        def to_json
          decorator_class(:version_decorator).new(version).to_json(decorator_options(environments: environments))
        end

        def delete_resource
          version_service.delete(version)
          true
        end

        def policy_name
          :'versions::version'
        end

        private

        def handle_request
          response_code = version ? 200 : 201
          @version = yield
          response.body = to_json
          response_code
        end

        def parsed_version
          @parsed_version ||= Decorators::VersionDecorator.new(OpenStruct.new).from_json(request_body)
        end

        def environments
          @environments ||= environment_service.find_for_pacticipant(version.pacticipant)
        end

        def version
          @version ||= version_service.find_by_pacticipant_name_and_number(identifier_from_path)
        end
      end
    end
  end
end
