require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/contracts/pacticipant_schema'

module PactBroker
  module Api
    module Resources
      class Pacticipant < BaseResource

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def content_types_accepted
          [["application/json", :from_json]]
        end

        def allowed_methods
          ["GET", "PUT", "PATCH", "DELETE", "OPTIONS"]
        end

        def known_methods
          super + ['PATCH']
        end

        def malformed_request?
          if request.patch?
            invalid_json? || validation_errors_for_schema?
          else
            false
          end
        end

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

        def parsed_pacticipant
          decorator_class(:pacticipant_decorator).new(OpenStruct.new).from_json(request_body)
        end

        def policy_name
          :'pacticipants::pacticipant'
        end

        def schema
          PactBroker::Api::Contracts::PacticipantSchema
        end

        def update_existing_pacticipant
          if request.really_put?
            @pacticipant = pacticipant_service.replace(pacticipant_name, parsed_pacticipant)
          else
            @pacticipant = pacticipant_service.update params(symbolize_names: false).merge('name' => pacticipant_name)
          end
        end

        def create_new_pacticipant
          pacticipant_service.create parsed_pacticipant.to_h.merge(:name => pacticipant_name)
        end
      end
    end
  end
end
