require "pact_broker/api/resources/matrix"
require "pact_broker/matrix/can_i_deploy_query_schema"
require "pact_broker/matrix/parse_can_i_deploy_query"
require "pact_broker/messages"

module PactBroker
  module Api
    module Resources
      class CanIDeploy < Matrix
        include PactBroker::Messages

        def malformed_request?
          if (errors = query_schema.call(query_params)).any?
            set_json_validation_error_messages(errors)
            true
          elsif !pacticipant
            set_json_validation_error_messages(pacticipant: [message("errors.validation.pacticipant_not_found", name: pacticipant_name)])
            true
          else
            false
          end
        end

        def policy_name
          :'matrix::can_i_deploy'
        end

        private

        def query_schema
          PactBroker::Api::Contracts::CanIDeployQuerySchema
        end

        def pacticipant
          @pacticipant ||= pacticipant_service.find_pacticipant_by_name(pacticipant_name)
        end

        def pacticipant_name
          selectors.first.pacticipant_name
        end

        def parsed_query
          @parsed_query ||= PactBroker::Matrix::ParseCanIDeployQuery.call(query_params)
        end

        def query_params
          @query_params ||= JSON.parse(Rack::Utils.parse_nested_query(request.uri.query).to_json, symbolize_names: true)
        end
      end
    end
  end
end
