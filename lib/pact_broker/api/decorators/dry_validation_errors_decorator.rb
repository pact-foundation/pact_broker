# Formats Dry::Validation::MessageSet errors into the "old" Pact Broker errors format
# TODO: delete this in favour of problem+json in the next major version

require "pact_broker/api/contracts/dry_validation_errors_formatter"

module PactBroker
  module Api
    module Decorators
      class DryValidationErrorsDecorator

        # @param errors [Hash]
        def initialize(errors)
          @errors = errors
        end

        # @return [Hash]
        def to_hash(*_args, **_kwargs)
          { errors: PactBroker::Api::Contracts::DryValidationErrorsFormatter.format_errors(errors) }
        end

        # @return [String] JSON
        def to_json(*args, **kwargs)
          to_hash(*args, **kwargs).to_json
        end

        private

        attr_reader :errors
      end
    end
  end
end
