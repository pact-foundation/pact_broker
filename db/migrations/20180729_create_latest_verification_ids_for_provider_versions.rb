require_relative "../ddl_statements"

Sequel.migration do
  change do
    create_view(:latest_verification_ids_for_pact_versions,
      LATEST_VERIFICATION_IDS_FOR_PACT_VERSIONS_V1)
  end
end
