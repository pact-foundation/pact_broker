require "pact_broker/api/resources/base_resource"
require "pact_broker/api/decorators/released_version_decorator"
require "pact_broker/messages"

module PactBroker
  module Api
    module Resources
      class ReleasedVersion < BaseResource
        include PactBroker::Messages

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def content_types_accepted
          [
            ["application/merge-patch+json", :from_merge_patch_json]
          ]
        end

        def allowed_methods
          ["GET", "PATCH", "OPTIONS"]
        end

        def patch_can_create?
          false
        end

        def resource_exists?
          !!released_version
        end

        def to_json
          decorator_class(:released_version_decorator).new(released_version).to_json(decorator_options)
        end

        def from_merge_patch_json
          if request.patch?
            if resource_exists?
              process_currently_supported_param
            else
              404
            end
          else
            415
          end
        end

        def policy_name
          :'versions::released_version'
        end

        def policy_record_context
          {
            pacticipant: released_version&.pacticipant
          }
        end

        def policy_record
          released_version&.environment
        end

        private

        # can't use ||= with a potentially nil value
        def currently_supported_param
          if defined?(@currently_deployed_param)
            @currently_supported_param
          else
            @currently_supported_param = params(default: {})[:currentlySupported]
          end
        end

        def process_currently_supported_param
          if currently_supported_param == false
            @released_version = released_version_service.record_version_support_ended(released_version)
            response.body = to_json
          elsif currently_supported_param == true
            set_json_validation_error_messages(currentlySupported: [message("errors.validation.cannot_set_currently_supported_true")])
            422
          else
            response.body = to_json
          end
        end

        def released_version
          @released_version ||= released_version_service.find_by_uuid(uuid)
        end

        def uuid
          identifier_from_path[:uuid]
        end
      end
    end
  end
end
