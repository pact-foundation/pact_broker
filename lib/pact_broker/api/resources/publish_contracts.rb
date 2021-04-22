require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/resources/webhook_execution_methods'
require 'pact_broker/contracts/contracts_to_publish'
require 'pact_broker/api/contracts/publish_contracts_schema'
require 'pact_broker/pacts/parse'

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
          @parsed_contracts ||= decorator_class(:publish_contracts_decorator).new(PactBroker::Contracts::ContractsToPublish.new).from_hash(params)
        end

        def params
          p = super(default: {}, symbolize_names: false)
          if p["contracts"].is_a?(Array)
            p["contracts"].each do | contract |
              contract["decodedContent"] = Base64.strict_decode64(contract["content"]) rescue nil
              if contract["decodedContent"]
                contract["decodedParsedContent"] = PactBroker::Pacts::Parse.call(contract["decodedContent"]) rescue nil
              end
            end
          end
          p
        end

        def schema
          PactBroker::Api::Contracts::PublishContractsSchema
        end
      end
    end
  end
end
