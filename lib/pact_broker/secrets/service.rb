require 'securerandom'
require 'pact_broker/secrets/secret'

module PactBroker
  module Secrets
    class Service
      extend PactBroker::Repositories

      def self.encryption_key_configured?(secrets_encryption_key_id)
        !!PactBroker.configuration.secrets_encryption_key_finder.call(key_id: secrets_encryption_key_id)
      rescue
        false
      end

      def self.next_uuid
        SecureRandom.urlsafe_base64
      end

      def self.create(uuid, unencrypted_secret, secrets_encryption_key_id)
        secret_repository.create(uuid, unencrypted_secret, secrets_encryption_key_id)
      end

      def self.find_all
        secret_repository.find_all
      end
    end
  end
end
