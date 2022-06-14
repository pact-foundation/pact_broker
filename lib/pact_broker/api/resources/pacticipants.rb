require "pact_broker/api/resources/base_resource"
require "pact_broker/api/decorators/pacticipant_decorator"
require "pact_broker/domain/pacticipant"
require "pact_broker/hash_refinements"
require "pact_broker/api/contracts/pacticipant_schema"

module PactBroker
  module Api
    module Resources
      class Pacticipants < BaseResource
        using PactBroker::HashRefinements

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def content_types_accepted
          [["application/json", :from_json]]
        end

        def allowed_methods
          ["GET", "POST", "OPTIONS"]
        end

        def malformed_request?
          super || (request.post? && validation_errors_for_schema?)
        end

        def request_body_required?
          request.post?
        end

        def post_is_create?
          true
        end

        def from_json
          created_model = pacticipant_service.create(parsed_pacticipant.to_h)
          response.body = decorator_for(created_model).to_json(decorator_options)
        end

        def create_path
          "/pacticpants/#{url_encode(params[:name])}"
        end

        def to_json
          generate_json(pacticipant_service.find_all_pacticipants)
        end

        def generate_json pacticipants
          decorator_class(:deprecated_pacticipant_collection_decorator).new(pacticipants).to_json(decorator_options)
        end

        def decorator_for model
          decorator_class(:pacticipant_decorator).new(model)
        end

        def parsed_pacticipant
          @new_model ||= decorator_for(OpenStruct.new).from_json(request_body)
        end

        def policy_name
          :'pacticipants::pacticipants'
        end

        private

        def schema
          PactBroker::Api::Contracts::PacticipantSchema
        end

        def pacticipants
          @pacticipants ||= pacticipant_service.find_all_pacticipants
        end
      end
    end
  end
end
