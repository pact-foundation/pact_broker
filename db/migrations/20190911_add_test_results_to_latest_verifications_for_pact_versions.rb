Sequel.migration do
  up do
    # The most recent verification for each pact_version
    v = :verifications
    create_or_replace_view(:latest_verifications_for_pact_versions,
      from(v)
        .select(
          Sequel[v][:id],
          Sequel[v][:number],
          Sequel[v][:success],
          Sequel[v][:build_url],
          Sequel[v][:pact_version_id],
          Sequel[v][:execution_date],
          Sequel[v][:created_at],
          Sequel[v][:provider_version_id],
          Sequel[:s][:number].as(:provider_version_number),
          Sequel[:s][:order].as(:provider_version_order),
          Sequel[v][:test_results])
        .join(:latest_verification_ids_for_pact_versions,
          {
            Sequel[v][:pact_version_id] => Sequel[:lv][:pact_version_id],
            Sequel[v][:id] => Sequel[:lv][:latest_verification_id]
          }, { table_alias: :lv })
        .join(:versions,
          {
            Sequel[v][:provider_version_id] => Sequel[:s][:id]
          }, { table_alias: :s })
    )
  end

  down do
    # do nothing - you can't drop columns from a postgres view
  end
end
