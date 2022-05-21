require "pact_broker/api/resources/base_resource"
require "pact_broker/api/decorators/deployed_version_decorator"
require "pact_broker/messages"

module PactBroker
  module Api
    module Resources
      class DeployedVersion < BaseResource
        include PactBroker::Messages

        def content_types_provided
          [
            ["application/hal+json", :to_json]
          ]
        end

        def content_types_accepted
          [
            ["application/merge-patch+json", :from_merge_patch_json]
          ]
        end

        def allowed_methods
          ["GET", "PATCH", "OPTIONS"]
        end

        def resource_exists?
          !!deployed_version
        end

        def to_json
          decorator_class(:deployed_version_decorator).new(deployed_version).to_json(decorator_options)
        end

        def from_merge_patch_json
          if request.patch?
            if resource_exists?
              process_currently_deployed_param
            else
              404
            end
          else
            415
          end
        end

        def policy_name
          :'versions::deployed_version'
        end

        def policy_record_context
          {
            pacticipant: deployed_version&.pacticipant
          }
        end

        def policy_record
          deployed_version&.environment
        end

        private

        # can't use ||= with a potentially nil value
        def currently_deployed_param
          if defined?(@currently_deployed_param)
            @currently_deployed_param
          else
            @currently_deployed_param = params(default: {})[:currentlyDeployed]
          end
        end

        def process_currently_deployed_param
          if currently_deployed_param == false
            @deployed_version = deployed_version_service.record_version_undeployed(deployed_version)
            response.body = to_json
          elsif currently_deployed_param == true
            set_json_validation_error_messages(currentlyDeployed: [message("errors.validation.cannot_set_currently_deployed_true")])
            422
          else
            response.body = to_json
          end
        end

        def deployed_version
          @deployed_version ||= deployed_version_service.find_by_uuid(uuid)
        end

        def uuid
          identifier_from_path[:uuid]
        end
      end
    end
  end
end
