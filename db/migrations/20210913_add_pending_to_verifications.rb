Sequel.migration do
  change do
    alter_table(:verifications) do
      add_column(:pending, TrueClass)
    end
  end
end
