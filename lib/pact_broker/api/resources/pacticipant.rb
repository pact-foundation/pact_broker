require "pact_broker/api/resources/base_resource"
require "pact_broker/api/contracts/pacticipant_schema"

module PactBroker
  module Api
    module Resources
      class Pacticipant < BaseResource

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

        def put_can_create?
          false
        end

        def known_methods
          super + ["PATCH"]
        end

        def malformed_request?
          super || ((request.patch? || request.really_put?) && validation_errors_for_schema?)
        end

        # PUT or PATCH with content-type application/json
        def from_json
          if pacticipant
            @pacticipant = update_existing_pacticipant
          else
            if request.patch? # for backwards compatibility, wish I hadn't done this
              @pacticipant = create_new_pacticipant
              response.headers["Location"] = pacticipant_url(base_url, pacticipant)
            else
              return 404
            end
          end
          response.body = to_json
        end

        def from_merge_patch_json
          if request.patch?
            from_json
          else
            415
          end
        end

        def resource_exists?
          !!pacticipant
        end

        def delete_resource
          pacticipant_service.delete(pacticipant_name)
          true
        end

        def to_json
          decorator_class(:pacticipant_decorator).new(pacticipant).to_json(decorator_options)
        end

        def parsed_pacticipant(pacticipant)
          decorator_class(:pacticipant_decorator).new(pacticipant).from_json(request_body)
        end

        def policy_name
          :'pacticipants::pacticipant'
        end

        def schema
          PactBroker::Api::Contracts::PacticipantSchema
        end

        def update_existing_pacticipant
          if request.really_put?
            @pacticipant = pacticipant_service.replace(pacticipant_name, parsed_pacticipant(OpenStruct.new))
          else
            @pacticipant = pacticipant_service.update(pacticipant_name, parsed_pacticipant(pacticipant))
          end
        end

        def create_new_pacticipant
          pacticipant_service.create parsed_pacticipant(OpenStruct.new).to_h.merge(:name => pacticipant_name)
        end
      end
    end
  end
end
