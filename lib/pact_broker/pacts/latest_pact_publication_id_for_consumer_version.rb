require "pact_broker/pacts/all_pact_publications"
require "pact_broker/repositories/helpers"

module PactBroker
  module Pacts
    class LatestPactPublicationIdForConsumerVersion < Sequel::Model(:latest_pact_publication_ids_for_consumer_versions)
      set_primary_key [:provider_id, :consumer_version_id]
      unrestrict_primary_key
      plugin :upsert, identifying_columns: [:provider_id, :consumer_version_id]

      dataset_module do
        include PactBroker::Repositories::Helpers
      end
    end
  end
end

# Table: latest_pact_publication_ids_for_consumer_versions
# Primary Key: (provider_id, consumer_version_id)
# Columns:
#  consumer_id         | integer                     | NOT NULL
#  consumer_version_id | integer                     | NOT NULL
#  provider_id         | integer                     | NOT NULL
#  pact_publication_id | integer                     | NOT NULL
#  pact_version_id     | integer                     | NOT NULL
#  created_at          | timestamp without time zone |
# Indexes:
#  latest_pact_publication_ids_for_consume_pact_publication_id_key | UNIQUE btree (pact_publication_id)
#  unq_latest_ppid_prov_conver                                     | UNIQUE btree (provider_id, consumer_version_id)
#  lpp_provider_id_consumer_id_index                               | btree (provider_id, consumer_id)
# Foreign key constraints:
#  latest_pact_publication_ids_for_consum_consumer_version_id_fkey | (consumer_version_id) REFERENCES versions(id) ON DELETE CASCADE
#  latest_pact_publication_ids_for_consum_pact_publication_id_fkey | (pact_publication_id) REFERENCES pact_publications(id) ON DELETE CASCADE
#  latest_pact_publication_ids_for_consumer_v_pact_version_id_fkey | (pact_version_id) REFERENCES pact_versions(id) ON DELETE CASCADE
#  latest_pact_publication_ids_for_consumer_versi_consumer_id_fkey | (consumer_id) REFERENCES pacticipants(id) ON DELETE CASCADE
#  latest_pact_publication_ids_for_consumer_versi_provider_id_fkey | (provider_id) REFERENCES pacticipants(id) ON DELETE CASCADE
