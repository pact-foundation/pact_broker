
module PactBroker
  module Api
    module Resources
      class CanIDeploy < Matrix
        include PactBroker::Messages

        # Can't call super because it will execute the Matrix validation, not the BaseResource validation
        def malformed_request?
          request.get? && validation_errors_for_schema?(schema, request.query)
        end

        def policy_name
          :'matrix::can_i_deploy'
        end

        private

        def schema
          PactBroker::Api::Contracts::CanIDeployQuerySchema
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
