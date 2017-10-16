Sequel.migration do
  change do
    alter_table(:verifications) do
      set_column_allow_null(:provider_version)
    end
  end
end
