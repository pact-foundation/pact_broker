require "pact_broker/api/contracts/base_contract"
require "pact_broker/api/contracts/utf_8_validation"

# The contract for the contract object in the publish contracts request
module PactBroker
  module Api
    module Contracts
      class PublishContractsContractContract < BaseContract
        json do
          required(:consumerName).filled(:string)
          required(:providerName).filled(:string)
          required(:content).filled(:string)
          required(:contentType).filled(included_in?: ["application/json"])
          required(:specification).filled(included_in?: ["pact"])
          optional(:onConflict).filled(included_in?:["overwrite", "merge"])
          optional(:decodedParsedContent) # set in the resource
          optional(:decodedContent) # set in the resource
        end

        rule(:consumerName).validate(:not_blank_if_present)
        rule(:providerName).validate(:not_blank_if_present)

        # validate_encoding (ensure all UTF-8 chars)
        rule(:decodedContent) do
          if value.nil?
            base.failure(validation_message("base64"))
          end

          if value
            char_number, fragment = PactBroker::Api::Contracts::UTF8Validation.fragment_before_invalid_utf_8_char(value)
            if char_number
              base.failure(validation_message("non_utf_8_char_in_contract", char_number: char_number, fragment: fragment))
            end
          end
        end

        # validate content could be parsed according to its content type
        rule(:decodedParsedContent, :contentType) do
          if values[:decodedParsedContent].nil? && values[:contentType]
            base.failure(validation_message("invalid_content_for_content_type", { content_type: values[:contentType] }))
          end
        end

        # validate parsed contract is a hash
        rule(:decodedParsedContent, :contentType) do
          if !base_rule_error? && !values[:decodedParsedContent].is_a?(Hash)
            base.failure(validation_message("invalid_parsed_contract_class", { actual_class: values[:decodedParsedContent].class }))
          end
        end

        # validate consumer name in content matches the details higher in the JSON document
        rule(:decodedParsedContent, :consumerName, :specification) do
          if !base_rule_error?
            consumer_name_in_content = values.dig(:decodedParsedContent, :consumer, :name)
            if consumer_name_in_content && consumer_name_in_content != values[:consumerName]
              base.failure(validation_message("consumer_name_in_content_mismatch", { consumer_name_in_content: consumer_name_in_content, consumer_name: values[:consumerName] }))
            end
          end
        end

        # validate provider name in content matches the details higher in the JSON document
        rule(:decodedParsedContent, :providerName) do
          if !base_rule_error?
            provider_name_in_content = values.dig(:decodedParsedContent, :provider, :name)
            if provider_name_in_content && provider_name_in_content != values[:providerName]
              base.failure(validation_message("provider_name_in_content_mismatch", { provider_name_in_content: provider_name_in_content, provider_name: values[:providerName] }))
            end
          end
        end
      end
    end
  end
end
