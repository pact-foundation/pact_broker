require_relative '../ddl_statements'

Sequel.migration do
  up do
    create_or_replace_view(:latest_pact_publications_by_consumer_versions,
      latest_pact_publications_by_consumer_versions_v3(self))
  end

  down do
    create_or_replace_view(:latest_pact_publications_by_consumer_versions,
      latest_pact_publications_by_consumer_versions_v2(self))
  end
end
