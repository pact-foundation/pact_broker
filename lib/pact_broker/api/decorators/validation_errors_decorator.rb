# Formats a nested Hash of errors, or an Array of Strings, into the "old" Pact Broker errors format
# TODO: delete this in favour of problem+json in the next major version

module PactBroker
  module Api
    module Decorators
      class ValidationErrorsDecorator

        # @param errors [Hash, Array<String>]
        def initialize(errors)
          @errors = errors
        end

        # @return [Hash]
        def to_hash(*_args, **_kwargs)
          { errors: errors }
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
