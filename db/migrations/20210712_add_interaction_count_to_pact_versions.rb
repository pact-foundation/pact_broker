Sequel.migration do
  change do
    alter_table(:pact_versions) do
      add_column(:messages_count, Integer)
      add_column(:interactions_count, Integer)
    end
  end
end
