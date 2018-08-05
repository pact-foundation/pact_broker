require_relative '../ddl_statements'

Sequel.migration do
  change do
    create_view(:latest_verification_ids_for_provider_versions,
      LATEST_VERIFICATION_IDS_FOR_PROVIDER_VERSIONS_V1)
  end
end
