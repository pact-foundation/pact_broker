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

      def update(uuid, unencrypted_secret, secrets_encryption_key_id)
        secret = Secret.where(uuid: uuid).single_record
        secret.name = unencrypted_secret.name
        secret.key_id = secrets_encryption_key_id
        secret.value = unencrypted_secret.value
        secret.save
        UnencryptedSecret.new(secret.to_hash)
      end

      def find_all
        Secret.order(:name).collect{ | secret | UnencryptedSecret.new(secret.to_hash) }
      end

      def find_by_uuid(uuid)
        Secret.where(uuid: uuid).collect{ | secret | UnencryptedSecret.new(secret.to_hash) }.first
      end

      def delete_by_uuid(uuid)
        Secret.where(uuid: uuid).delete
      end
    end
  end
end
