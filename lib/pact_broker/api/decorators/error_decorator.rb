# Formats a nested Hash of errors into the "old" Pact Broker errors format
# TODO: delete this in favour of problem+json in the next major version

module PactBroker
  module Api
    module Decorators
      class ErrorDecorator

        # @param error [String]
        def initialize(error)
          @error = error
        end

        # @return [Hash]
        def to_hash(*_args, **_kwargs)
          { error: error }
        end

        # @return [String] JSON
        def to_json(*args, **kwargs)
          to_hash(*args, **kwargs).to_json
        end

        private

        attr_reader :error
      end
    end
  end
end
