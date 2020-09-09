require 'pact_broker/api/resources/matrix'
require 'pact_broker/matrix/can_i_deploy_query_schema'
require 'pact_broker/matrix/parse_can_i_deploy_query'

module PactBroker
  module Api
    module Resources
      class CanIDeploy < Matrix
        def initialize
          super
          @query_params = JSON.parse(Rack::Utils.parse_nested_query(request.uri.query).to_json, symbolize_names: true)
          @selectors, @options = PactBroker::Matrix::ParseCanIDeployQuery.call(query_params)
        end

        def malformed_request?
          if (errors = query_schema.call(query_params)).any?
            set_json_validation_error_messages(errors)
            true
          else
            false
          end
        end

        def policy_name
          :'matrix::can_i_deploy'
        end

        private

        attr_reader :query_params, :selectors, :options

        def query_schema
          PactBroker::Api::Contracts::CanIDeployQuerySchema
        end
      end
    end
  end
end
