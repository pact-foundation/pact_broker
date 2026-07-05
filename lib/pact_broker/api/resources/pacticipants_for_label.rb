require "pact_broker/api/resources/base_resource"
require "pact_broker/api/decorators/pacticipants_decorator"
require "pact_broker/api/resources/pagination_methods"

module PactBroker
  module Api
    module Resources
      class PacticipantsForLabel < BaseResource
        include PaginationMethods

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def malformed_request?
          if super
            true
          elsif request.get? && validation_errors_for_schema?(schema, request.query)
            true
          else
            false
          end
        end

        def to_json
          generate_json(pacticipant_service.find_all_pacticipants(filter_options, pagination_options, eager_load_associations))
        end

        def generate_json pacticipants
          decorator_class(:pacticipants_decorator).new(pacticipants).to_json(**decorator_options)
        end

        def policy_name
          :'pacticipants::pacticipants'
        end

        private

        def schema
          PactBroker::Api::Contracts::PaginationQueryParamsSchema
        end

        def eager_load_associations
          decorator_class(:pacticipants_decorator).eager_load_associations
        end

        def filter_options
          options = { label_name: identifier_from_path[:label_name] }
          options[:query_string] = request.query["q"] if request.query.has_key?("q")
          options
        end
      end
    end
  end
end
