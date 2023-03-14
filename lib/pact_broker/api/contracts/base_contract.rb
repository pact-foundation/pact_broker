require "dry-validation"
require "pact_broker/api/contracts/dry_validation_macros"
require "pact_broker/api/contracts/dry_validation_methods"
require "pact_broker/api/contracts/dry_validation_errors_formatter"
require "pact_broker/messages"
require "pact_broker/hash_refinements"

module PactBroker
  module Api
    module Contracts
      class BaseContract < Dry::Validation::Contract
        include DryValidationMethods
        extend DryValidationErrorsFormatter

        using PactBroker::HashRefinements

        # The entry method for all the Dry::Validation::Contract classes
        # eg. MyContract.call(params)
        # It takes the params (doesn't matter if they're string or symbol keys)
        # executes the dry-validation validation, and formats the errors into the Pactflow format.
        #
        # @param [Hash] the parameters to validate
        # @return [Hash] the validation errors to display to the user
        def self.call(params)
          format_errors(new.call(params&.symbolize_keys).errors)
        end
      end
    end
  end
end
