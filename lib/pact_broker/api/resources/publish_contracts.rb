require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/resources/webhook_execution_methods'
require 'pact_broker/contracts/contracts_to_publish'
require 'pact_broker/api/contracts/publish_contracts_schema'

module PactBroker
  module Api
    module Resources
      class PublishContracts < BaseResource
        include WebhookExecutionMethods

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def content_types_accepted
          [["application/json"]]
        end

        def allowed_methods
          ["POST", "OPTIONS"]
        end

        def malformed_request?
          if request.post?
            invalid_json? || validation_errors_for_schema?
          else
            false
          end
        end

        def process_post
          results = contract_service.publish(parsed_contracts, webhook_options)
          response.body = decorator_class(:publish_contracts_results_decorator).new(results).to_json(decorator_options)
          true
        end

        def policy_name
          :'contracts::contracts'
        end

        # for Pactflow
        def policy_record
          @policy_record ||= pacticipant_service.find_pacticipant_by_name(parsed_contracts.pacticipant_name)
        end

        private

        def parsed_contracts
          @parsed_contracts ||= decorator_class(:publish_contracts_decorator).new(PactBroker::Contracts::ContractsToPublish.new).from_json(request_body)
        end

        def schema
          PactBroker::Api::Contracts::PublishContractsSchema
        end
      end
    end
  end
end
