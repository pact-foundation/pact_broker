require "dry-validation"
require "pact_broker/api/contracts/dry_validation_workarounds"
require "pact_broker/api/contracts/dry_validation_predicates"
require "pact_broker/messages"

module PactBroker
  module Api
    module Contracts
      class EnvironmentSchema
        extend DryValidationWorkarounds
        extend PactBroker::Messages
        using PactBroker::HashRefinements

        SCHEMA = Dry::Validation.Schema do
          configure do
            predicates(DryValidationPredicates)
            config.messages_file = File.expand_path("../../../locale/en.yml", __FILE__)
          end
          required(:name).filled(:str?, :single_line?, :no_spaces?)
          optional(:displayName).maybe(:str?, :single_line?)
          required(:production).filled(included_in?: [true, false])
          optional(:contacts).each do
            schema do
              required(:name).filled(:str?, :single_line?)
              optional(:details).schema do
              end
            end
          end
        end

        def self.call(params_with_string_keys)
          params = params_with_string_keys&.symbolize_keys
          results = select_first_message(flatten_indexed_messages(SCHEMA.call(params).messages(full: true)))
          validate_name(params, results)
          results
        end

        def self.validate_name(params, results)
          if (environment_with_same_name = PactBroker::Deployments::EnvironmentService.find_by_name(params[:name]))
            if environment_with_same_name.uuid != params[:uuid]
              results[:name] ||= []
              results[:name] << message("errors.validation.environment_name_must_be_unique", name: params[:name])
            end
          end
        end
      end
    end
  end
end
