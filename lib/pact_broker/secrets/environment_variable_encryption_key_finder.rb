require 'base64'

# Expects that the key has been base 64 encoded (no new line on the end)
# and has been set in the PACT_BROKER_SECRETS_ENCRYPTION_KEY environment variable

module PactBroker
  module Secrets
    class EnvironmentVariableEncryptionKeyFinder
      def self.call(*args)
        Base64.strict_decode64(ENV.fetch("PACT_BROKER_SECRETS_ENCRYPTION_KEY"))
      end
    end
  end
end