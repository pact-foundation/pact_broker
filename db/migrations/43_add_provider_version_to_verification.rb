Sequel.migration do
  change do
    alter_table(:verifications) do
      add_foreign_key(:provider_version_id, :versions, foreign_key_constraint_name: 'fk_verifications_versions')
    end
  end

  # TODO
  # alter_table(:verifications) do
  #   set_column_not_null(:provider_version_id)
  # end
end
