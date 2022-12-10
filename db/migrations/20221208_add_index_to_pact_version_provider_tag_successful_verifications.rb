require_relative "migration_helper"

include PactBroker::MigrationHelper

Sequel.migration do
  up do
    if !mysql?
      alter_table(:pact_version_provider_tag_successful_verifications) do
        add_index([:verification_id], name: "pact_ver_prov_tag_success_verif_verif_id_ndx")
      end
    end
  end

  down do
    if !mysql?
      alter_table(:pact_version_provider_tag_successful_verifications) do
        drop_index([:verification_id], name: "pact_ver_prov_tag_success_verif_verif_id_ndx")
      end
    end
  end
end
