Sequel.migration do
  change do
    alter_table(:pact_versions) do
      add_column(:has_http_interactions, TrueClass)
    end
  end
end
