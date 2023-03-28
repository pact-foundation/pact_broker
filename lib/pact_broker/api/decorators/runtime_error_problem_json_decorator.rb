# Formats a message string into application/problem+json format.

module PactBroker
  module Api
    module Decorators
      class RuntimeErrorProblemJSONDecorator

        # @param message [String]
        def initialize(message)
          @message = message
        end

        # @return [Hash]
        def to_hash(user_options:, **)
          {
            "title" => "Server error",
            "type" => "#{user_options[:base_url]}/problems/server_error",
            "detail" => message,
            "status" => 500
          }
        end

        # @return [String] JSON
        def to_json(*args, **kwargs)
          to_hash(*args, **kwargs).to_json
        end

        private

        attr_reader :message
      end
    end
  end
end
