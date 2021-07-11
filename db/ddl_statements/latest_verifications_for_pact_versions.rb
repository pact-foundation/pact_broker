def latest_verifications_for_pact_versions_v4(connection)
  v = :verifications
  connection.from(v)
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
      Sequel[v][:test_results],
      Sequel[v][:consumer_id],
      Sequel[v][:provider_id],
    )
    .join(:latest_verification_ids_for_pact_versions,
      {
        Sequel[v][:pact_version_id] => Sequel[:lv][:pact_version_id],
        Sequel[v][:id] => Sequel[:lv][:latest_verification_id]
      }, { table_alias: :lv })
    .join(:versions,
      {
        Sequel[v][:provider_version_id] => Sequel[:s][:id]
      }, { table_alias: :s })
end
