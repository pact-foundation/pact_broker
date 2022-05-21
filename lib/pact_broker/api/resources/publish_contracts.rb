require "pact_broker/api/resources/base_resource"
require "pact_broker/api/resources/webhook_execution_methods"
require "pact_broker/contracts/contracts_to_publish"
require "pact_broker/api/contracts/publish_contracts_schema"
require "pact_broker/pacts/parse"

module PactBroker
  module Api
    module Resources
      class PublishContracts < BaseResource
        include WebhookExecutionMethods

        def content_types_provided
          [["application/hal+json"]]
        end

        def allowed_methods
          ["POST", "OPTIONS"]
        end

        def malformed_request?
          super || (request.post? && content_type_json? && validation_errors_for_schema?)
        end

        def process_post
          if content_type_json?
            if conflict_notices.any?
              set_conflict_response
              409
            else
              publish_contracts
              true
            end
          else
            415
          end
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
              if contract.is_a?(Hash)
                decode_and_parse_content(contract)
              end
            end
          end
          p
        end

        def schema
          api_contract_class(:publish_contracts_schema)
        end

        def decode_and_parse_content(contract)
          contract["decodedContent"] = base64_decode(contract["content"])
          if contract["decodedContent"]
            if contract["contentType"]&.include?("json")
              contract["decodedParsedContent"] = parse_json(contract["decodedContent"])
            elsif contract["contentType"]&.include?("yml")
              contract["decodedParsedContent"] = parse_yaml(contract["decodedContent"])
            end
          end
        end

        def publish_contracts
          handle_webhook_events(consumer_version_branch: parsed_contracts.branch, build_url: parsed_contracts.build_url) do
            results = contract_service.publish(parsed_contracts, base_url: base_url)
            response.body = decorator_class(:publish_contracts_results_decorator).new(results).to_json(decorator_options)
          end
        end

        def set_conflict_response
          response.body = {
            notices: conflict_notices.collect(&:to_h),
            errors: {
              contracts: conflict_notices.select(&:error?).collect(&:text)
            }
          }.to_json
          response.headers["Content-Type"] = "application/json;charset=utf-8"
        end

        def conflict_notices
          @conflict_notices ||= contract_service.conflict_notices(parsed_contracts, base_url: base_url)
        end

        def base64_decode(content)
          Base64.strict_decode64(content) rescue nil
        end

        # TODO put this somewhere shareable
        def parse_yaml(content)
          YAML.safe_load(content, [Time, Date, DateTime]) rescue nil
        end

        def parse_json(content)
          PactBroker::Pacts::Parse.call(content) rescue nil
        end
      end
    end
  end
end
