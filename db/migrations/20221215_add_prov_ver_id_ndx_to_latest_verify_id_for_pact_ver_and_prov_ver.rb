require_relative "migration_helper"

include PactBroker::MigrationHelper

Sequel.migration do
  up do
    if !mysql?
      alter_table(:latest_verification_id_for_pact_version_and_provider_version) do
        add_index([:provider_version_id], name: "latest_verif_id_for_pact_ver_and_prov_ver_prov_ver_id_ndx")
      end
    end
  end

  down do
    if !mysql?
      alter_table(:latest_verification_id_for_pact_version_and_provider_version) do
        drop_index([:provider_version_id], name: "latest_verif_id_for_pact_ver_and_prov_ver_prov_ver_id_ndx")
      end
    end
  end
end
