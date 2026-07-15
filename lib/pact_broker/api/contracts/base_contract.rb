require "dry-validation"

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
          params_to_validate = params.respond_to?(:symbolize_keys) ? params.symbolize_keys : params
          new.call(params_to_validate)
        end
      end
    end
  end
end
