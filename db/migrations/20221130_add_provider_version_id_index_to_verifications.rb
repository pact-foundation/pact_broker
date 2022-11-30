require_relative "migration_helper"

include PactBroker::MigrationHelper

Sequel.migration do
  up do
    alter_table(:verifications) do
      add_index([:provider_version_id], name: "verifications_provider_version_id_index")
    end

  end

  down do
    if !mysql?
      # MySQL automatically creates indexes for foreign keys then complains if you
      # re-create it with a different name and try to drop it.

      # https://stackoverflow.com/a/52274628/832671 - "When there is only one index that can be used
      # for the foreign key, it can't be dropped. If you really wan't to drop it, you either have to drop
      # the foreign key constraint or to create another index for it first."
      alter_table(:verifications) do
        drop_index([:provider_version_id], name: "verifications_provider_version_id_index")
      end
    end
  end
end
