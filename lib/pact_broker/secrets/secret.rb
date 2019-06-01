require 'sequel'
require 'attr_encrypted'
require 'securerandom'
require 'pact_broker/configuration'

module PactBroker
  module Secrets
    class Secret < Sequel::Model
      plugin :timestamps, update_on_create: true
      plugin :after_initialize
      attr_encrypted :value, key: :encryption_key, algorithm: :algorithm, encode: true, encode_iv: true, allow_empty_value: true, marshal: true

      def after_initialize
        super
        self.uuid ||= SecureRandom.urlsafe_base64
        self.algorithm ||= "aes-256-gcm"
      end

      def encryption_key
        PactBroker.configuration.secrets_encryption_key_finder.call(key_id: key_id)
      end
    end
  end
end
