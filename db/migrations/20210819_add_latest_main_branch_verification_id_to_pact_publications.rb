Sequel.migration do
  change do
    alter_table(:pact_publications) do
      # Can't be a foreign key, or we'd have a circular dependency
      add_column(:latest_main_verification_id, Integer)
      add_column(:last_verified_at, DateTime)
    end
  end
end
