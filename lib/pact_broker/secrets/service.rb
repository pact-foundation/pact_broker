require 'securerandom'
require 'pact_broker/secrets/secret'

module PactBroker
  module Secrets
    class Service

      def self.encryption_key_configured?(secrets_encryption_key_id)
        !!PactBroker.configuration.secrets_encryption_key_finder.call(key_id: secrets_encryption_key_id)
      rescue
        false
      end

      def self.next_uuid
        SecureRandom.urlsafe_base64
      end

      def self.create(uuid, unencrypted_secret, secrets_encryption_key_id)
        secret = Secret.new(
          uuid: uuid,
          name: unencrypted_secret.name,
          key_id: secrets_encryption_key_id
        )
        secret.value = unencrypted_secret.value
        secret.save
        UnencryptedSecret.new(secret.to_hash)
      end
    end
  end
end
