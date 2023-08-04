require "pact_broker/api/resources/base_resource"
require "pact_broker/api/decorators/pacticipant_decorator"
require "pact_broker/domain/pacticipant"
require "pact_broker/hash_refinements"
require "pact_broker/api/contracts/pacticipant_create_schema"
require "pact_broker/api/resources/pagination_methods"

module PactBroker
  module Api
    module Resources
      class Pacticipants < BaseResource
        using PactBroker::HashRefinements
        include PaginationMethods

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
          if super
            true
          elsif request.post? && validation_errors_for_schema?
            true
          elsif request.get? && validation_errors_for_schema?(schema, request.query)
            true
          else
            false
          end
        end

        def request_body_required?
          request.post?
        end

        def post_is_create?
          true
        end

        def from_json
          created_model = pacticipant_service.create(parsed_pacticipant.to_h)
          response.body = decorator_for(created_model).to_json(**decorator_options)
        end

        def create_path
          "/pacticpants/#{url_encode(params[:name])}"
        end

        def to_json
          generate_json(pacticipant_service.find_all_pacticipants(filter_options, pagination_options, eager_load_associations))
        end

        def generate_json pacticipants
          decorator_class(:deprecated_pacticipants_decorator).new(pacticipants).to_json(**decorator_options)
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
          if request.get?
            PactBroker::Api::Contracts::PaginationQueryParamsSchema
          else
            PactBroker::Api::Contracts::PacticipantCreateSchema
          end
        end

        def eager_load_associations
          decorator_class(:deprecated_pacticipants_decorator).eager_load_associations
        end

        def filter_options
          if (request.query.has_key?("q"))
            { query_string: request.query["q"] }
          else
            {}
          end
        end
      end
    end
  end
end
