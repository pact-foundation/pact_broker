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

# Table: secrets
# Columns:
#  id                 | integer                     | PRIMARY KEY DEFAULT nextval('secrets_id_seq'::regclass)
#  uuid               | text                        | NOT NULL
#  name               | text                        | NOT NULL
#  description        | text                        |
#  encrypted_value    | text                        | NOT NULL
#  encrypted_value_iv | text                        | NOT NULL
#  key_id             | text                        |
#  algorithm          | text                        | NOT NULL
#  created_at         | timestamp without time zone | NOT NULL
#  updated_at         | timestamp without time zone | NOT NULL
# Indexes:
#  secrets_pkey        | PRIMARY KEY btree (id)
#  uq_secrets_name     | UNIQUE btree (name)
#  uq_secrets_uuid     | UNIQUE btree (uuid)
#  uq_secrets_value_iv | UNIQUE btree (encrypted_value_iv)
