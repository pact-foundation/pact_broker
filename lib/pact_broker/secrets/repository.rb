module PactBroker
  module Secrets
    class Repository
      def create(uuid, unencrypted_secret, secrets_encryption_key_id)
        secret = Secret.new(
          uuid: uuid,
          name: unencrypted_secret.name,
          key_id: secrets_encryption_key_id
        )
        secret.value = unencrypted_secret.value
        secret.save
        UnencryptedSecret.new(secret.to_hash)
      end

      def find_all
        Secret.order(:name).collect{ | secret | UnencryptedSecret.new(secret.to_hash) }
      end
    end
  end
end
