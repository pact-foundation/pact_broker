require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/decorators/environment_decorator'
require 'pact_broker/api/contracts/environment_contract'

module PactBroker
  module Api
    module Resources
      class VersionEnvironment < BaseResource
        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def content_types_accepted
          [["application/json", :from_json]]
        end

        def allowed_methods
          ["GET","PUT","DELETE"]
        end

        def malformed_request?
          if request.put?
            contract_validation_errors?(Contracts::EnvironmentContract.new(PactBroker::Environments::VersionEnvironment.new), identifier_from_path)
          else
            false
          end
        end

        def from_json
          unless environment
            @environment = environment_service.create identifier_from_path
            # Make it return a 201 by setting the Location header
            response.headers["Location"] = environment_url(base_url, environment)
            matrix_service.refresh_environments(identifier_from_path)
          end
          response.body = to_json
        end

        def resource_exists?
          environment
        end

        def to_json
          PactBroker::Api::Decorators::EnvironmentDecorator.new(environment).to_json(user_options: { base_url: base_url })
        end

        def environment
          @environment ||= environment_service.find identifier_from_path
        end

        def delete_resource
          matrix_service.refresh_environments(identifier_from_path) do
            environment_service.delete identifier_from_path
          end
          true
        end
      end
    end
  end
end
