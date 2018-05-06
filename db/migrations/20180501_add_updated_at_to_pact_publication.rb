Sequel.migration do
  change do
    alter_table(:pact_publications) do
      add_column(:updated_at, DateTime, null: true)
      # TODO make null false
    end
  end
end
