require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/decorators/pacticipant_decorator'
require 'pact_broker/domain/pacticipant'

module PactBroker
  module Api
    module Resources

      class Pacticipants < BaseResource

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
          if request.post?
            return invalid_json? || validation_errors?(new_model)
          end
          false
        end

        def post_is_create?
          true
        end

        def from_json
          created_model = pacticipant_service.create(params)
          response.body = decorator_for(created_model).to_json(user_options: decorator_context)
        end

        def create_path
          "/pacticpants/#{url_encode(params[:name])}"
        end

        def to_json
          generate_json(pacticipant_service.find_all_pacticipants)
        end

        def generate_json pacticipants
          PactBroker::Api::Decorators::DeprecatedPacticipantCollectionDecorator.new(pacticipants).to_json(user_options: { base_url: base_url })
        end

        def decorator_for model
          PactBroker::Api::Decorators::PacticipantDecorator.new(model)
        end

        def new_model
          @new_model ||= decorator_for(PactBroker::Domain::Pacticipant.new).from_json(request.body.to_s)
        end
      end
    end
  end
end
