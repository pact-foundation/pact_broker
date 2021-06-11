require "sequel"
require "pact_broker/messages"

module PactBroker
  module DB

    class ConnectionConfigurationError < StandardError; end

    class ValidateEncoding

      extend PactBroker::Messages

      def self.call connection
        encoding = connection.opts[:encoding] || connection.opts["encoding"]
        unless encoding =~ /utf\-?8/i
          raise ConnectionConfigurationError.new(message("errors.validation.connection_encoding_not_utf8", encoding: encoding.inspect))
        end
      end

    end
  end
end
