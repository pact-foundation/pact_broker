Sequel.migration do
  change do
    alter_table(:verifications) do
      add_column(:pact_pending, TrueClass)
    end
  end
end
