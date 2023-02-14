require "pact_broker/domain/verification"

module PactBroker
  module Verifications
    class LatestVerificationIdForPactVersionAndProviderVersion < Sequel::Model(:latest_verification_id_for_pact_version_and_provider_version)
      set_primary_key [:pact_version_id, :provider_version_id]
      unrestrict_primary_key

      plugin :upsert, identifying_columns: [:pact_version_id, :provider_version_id]

      dataset_module do
        include PactBroker::Repositories::Helpers
      end
    end
  end
end

# Table: latest_verification_id_for_pact_version_and_provider_version
# Primary Key: (pact_version_id, provider_version_id)
# Columns:
#  consumer_id         | integer                     | NOT NULL
#  pact_version_id     | integer                     | NOT NULL
#  provider_id         | integer                     | NOT NULL
#  provider_version_id | integer                     | NOT NULL
#  verification_id     | integer                     | NOT NULL
#  created_at          | timestamp without time zone |
# Indexes:
#  latest_v_id_for_pv_and_pv_pv_id_pv_id_unq | UNIQUE btree (pact_version_id, provider_version_id)
#  latest_v_id_for_pv_and_pv_v_id_unq        | UNIQUE btree (verification_id)
#  latest_v_id_for_pv_and_pv_pv_id_v_id      | btree (pact_version_id, verification_id)
# Foreign key constraints:
#  latest_v_id_for_pv_and_pv_consumer_id_fk         | (consumer_id) REFERENCES pacticipants(id) ON DELETE CASCADE
#  latest_v_id_for_pv_and_pv_pact_version_id_fk     | (pact_version_id) REFERENCES pact_versions(id) ON DELETE CASCADE
#  latest_v_id_for_pv_and_pv_provider_id_fk         | (provider_id) REFERENCES pacticipants(id) ON DELETE CASCADE
#  latest_v_id_for_pv_and_pv_provider_version_id_fk | (provider_version_id) REFERENCES versions(id) ON DELETE CASCADE
#  latest_v_id_for_pv_and_pv_verification_id_fk     | (verification_id) REFERENCES verifications(id) ON DELETE CASCADE
