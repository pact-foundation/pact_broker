Sequel.migration do
  change do
    alter_table(:pact_versions) do
      add_column(:has_messages, TrueClass, default: false, null: false)
    end
  end
end
