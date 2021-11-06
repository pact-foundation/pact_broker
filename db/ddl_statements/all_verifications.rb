def all_verifications_v2(connection)
  # Need to fully qualify build_url because versions now has a build_url too.
  # We don't use this view any more but we get an error when modifying other tables and views
  # if we don't update this, so it must force some re-calculation to be done.
  # See https://github.com/pact-foundation/pact_broker/issues/521
  connection
    .from(:verifications)
    .select(
      Sequel[:verifications][:id],
      Sequel[:verifications][:number],
      :success,
      :provider_version_id,
      Sequel[:v][:number].as(:provider_version_number),
      Sequel[:v][:order].as(:provider_version_order),
      Sequel[:verifications][:build_url],
      :pact_version_id,
      :execution_date,
      Sequel[:verifications][:created_at],
      :test_results
    ).join(:versions, { id: :provider_version_id }, { :table_alias => :v })
end
