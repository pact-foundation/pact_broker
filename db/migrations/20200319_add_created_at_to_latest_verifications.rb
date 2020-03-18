Sequel.migration do
  change do
    # TODO
    # alter_table(:latest_verification_id_for_pact_version_and_provider_version) do
    #   set_column_not_null(:created_at)
    # end
    add_column(:latest_verification_id_for_pact_version_and_provider_version, :created_at, DateTime)
  end
end
