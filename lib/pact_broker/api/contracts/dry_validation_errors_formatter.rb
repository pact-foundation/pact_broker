require "pact_broker/error"

module PactBroker
  module Api
    module Contracts
      module DryValidationErrorsFormatter

        # Formats the dry validation errors in the expected PactBroker error format of { :key => ["errors"] }
        # where there are no nested hashes.
        # @param [Dry::Validation::MessageSet] errors
        # @return [Hash]
        def format_errors(errors)
          errors.each_with_object({}) do | error, errors_hash |
            integers = error.path.select{ | k | k.is_a?(Integer) }

            if integers.size > 1
              raise PactBroker::Error,  "Cannot currently format an error message with more than one index"
            end

            if integers.empty?
              add_error(errors_hash, error.path.join(".").to_sym, error.text)
            else
              add_indexed_error(errors_hash, error)
            end
          end
        end

        # @private
        def add_error(errors_hash, key, text)
          errors_hash[key] ||= []
          errors_hash[key] << text
        end

        # @private
        def add_indexed_error(errors_hash, error)
          error_path_classes = error.path.collect(&:class)
          if error_path_classes == [Symbol, Integer, Symbol]
            add_error(errors_hash, error.path.first, "#{error.path.last} #{error.text} (at index #{error.path[1]})")
          elsif error_path_classes == [Symbol, Integer]
            add_error(errors_hash, error.path.first, "#{error.text} (at index #{error.path[1]})")
          else
            # Don't have any usecases for this - will deal with it when it happens
            raise PactBroker::Error, "Cannot currently format an error message with path classes #{error_path_classes}"
          end
        end
      end
    end
  end
end
