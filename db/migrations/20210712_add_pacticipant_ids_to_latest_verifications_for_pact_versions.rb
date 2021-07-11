require_relative '../ddl_statements'

Sequel.migration do
  up do
    create_or_replace_view(:latest_verifications_for_pact_versions, latest_verifications_for_pact_versions_v4(self))
  end

  down do

  end
end
