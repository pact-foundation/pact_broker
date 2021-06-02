require "pact_broker/db/data_migrations/set_latest_version_sequence_value"
Sequel.migration do
  change do
    create_table(:version_sequence_number) do
      Integer :value, null: false
    end
  end
end
