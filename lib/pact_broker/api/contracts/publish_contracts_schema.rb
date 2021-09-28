require "dry-validation"
require "pact_broker/api/contracts/dry_validation_workarounds"
require "pact_broker/api/contracts/dry_validation_predicates"
require "pact_broker/messages"

module PactBroker
  module Api
    module Contracts
      class PublishContractsSchema
        extend DryValidationWorkarounds
        using PactBroker::HashRefinements
        extend PactBroker::Messages

        SCHEMA = Dry::Validation.Schema do
          configure do
            predicates(DryValidationPredicates)
            config.messages_file = File.expand_path("../../../locale/en.yml", __FILE__)
          end

          required(:pacticipantName).filled(:str?, :not_blank?)
          required(:pacticipantVersionNumber).filled(:not_blank?, :single_line?)
          optional(:tags).each(:not_blank?, :single_line?)
          optional(:branch).maybe(:not_blank?, :single_line?)
          optional(:buildUrl).maybe(:single_line?)

          required(:contracts).each do
            required(:consumerName).filled(:str?, :not_blank?)
            required(:providerName).filled(:str?, :not_blank?)
            required(:content).filled(:str?)
            required(:contentType).filled(included_in?: ["application/json"])
            required(:specification).filled(included_in?: ["pact"])
            optional(:onConflict).filled(included_in?:["overwrite", "merge"])
          end
        end

        def self.call(params)
          dry_results = SCHEMA.call(params&.symbolize_keys).messages(full: true)
          dry_results.then do | results |
            add_cross_field_validation_errors(params&.symbolize_keys, results)
          end.then do | results |
            select_first_message(results)
          end.then do | results |
            flatten_indexed_messages(results)
          end
        end

        def self.add_cross_field_validation_errors(params, errors)
          if params[:contracts].is_a?(Array)
            params[:contracts].each_with_index do | contract, i |
              if contract.is_a?(Hash)
                validate_consumer_name(params, contract, i, errors)
                validate_consumer_name_in_content(params, contract, i, errors)
                validate_provider_name_in_content(contract, i, errors)
                validate_encoding(contract, i, errors)
                validate_content_matches_content_type(contract, i, errors)
              end
            end
          end
          errors
        end

        def self.validate_consumer_name(params, contract, i, errors)
          if params[:pacticipantName] && contract[:consumerName] && (contract[:consumerName] != params[:pacticipantName])
            add_contract_error(:consumerName, validation_message("consumer_name_in_contract_mismatch_pacticipant_name", { consumer_name_in_contract: contract[:consumerName], pacticipant_name: params[:pacticipantName] } ), i, errors)
          end
        end

        def self.validate_consumer_name_in_content(params, contract, i, errors)
          consumer_name_in_content = contract.dig(:decodedParsedContent, :consumer, :name)
          if consumer_name_in_content && consumer_name_in_content != params[:pacticipantName]
            add_contract_error(:consumerName, validation_message("consumer_name_in_content_mismatch_pacticipant_name", { consumer_name_in_content: consumer_name_in_content, pacticipant_name: params[:pacticipantName] } ), i, errors)
          end
        end

        def self.validate_provider_name_in_content(contract, i, errors)
          provider_name_in_content = contract.dig(:decodedParsedContent, :provider, :name)
          if provider_name_in_content && provider_name_in_content != contract[:providerName]
            add_contract_error(:providerName, validation_message("provider_name_in_content_mismatch", { provider_name_in_content: provider_name_in_content, provider_name: contract[:providerName] } ), i, errors)
          end
        end

        def self.validate_encoding(contract, i, errors)
          if contract[:decodedContent].nil?
            add_contract_error(:content, message("errors.base64?", scope: nil), i, errors)
          end
        end

        def self.validate_content_matches_content_type(contract, i, errors)
          if contract[:decodedParsedContent].nil? && contract[:contentType]
            add_contract_error(:content, validation_message("invalid_content_for_content_type", { content_type: contract[:contentType]}), i, errors)
          end
        end


        def self.add_contract_error(field, message, i, errors)
          errors[:contracts] ||= {}
          errors[:contracts][i] ||= {}
          errors[:contracts][i][field] ||= []
          errors[:contracts][i][field] << message
          errors
        end

        # Need to fix this whole dry-validation eff up
        def self.select_first_message(results)
          case results
          when Hash then results.each_with_object({}) { |(key, value), new_hash| new_hash[key] = select_first_message(value) }
          when Array then select_first_message_from_array(results)
          else
            results
          end
        end

        def self.select_first_message_from_array(results)
          if results.all?{ |value| value.is_a?(String) }
            results[0...1]
          else
            results.collect { |value| select_first_message(value) }
          end
        end
      end
    end
  end
end
