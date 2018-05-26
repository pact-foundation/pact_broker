Sequel.migration do
  up do
    # The latest verification id for each consumer version tag
    create_view(:latest_verification_ids_for_consumer_and_provider,
      "select
        pv.pacticipant_id as provider_id,
        lpp.consumer_id,
        max(v.id) as latest_verification_id
      from verifications v
      join latest_pact_publications_by_consumer_versions lpp
        on v.pact_version_id = lpp.pact_version_id
      join versions pv
        on v.provider_version_id = pv.id
      group by pv.pacticipant_id, lpp.consumer_id")

    # The most recent verification for each consumer/consumer version tag/provider
    latest_verifications = from(:verifications)
      .select(
        Sequel[:lv][:consumer_id],
        Sequel[:lv][:provider_id],
        Sequel[:pv][:sha].as(:pact_version_sha),
        Sequel[:prv][:number].as(:provider_version_number),
        Sequel[:prv][:order].as(:provider_version_order),
        )
      .select_append{ verifications.* }
      .join(:latest_verification_ids_for_consumer_and_provider,
        {
          Sequel[:verifications][:id] => Sequel[:lv][:latest_verification_id],
        }, { table_alias: :lv })
      .join(:versions,
        {
          Sequel[:verifications][:provider_version_id] => Sequel[:prv][:id]
        }, { table_alias: :prv })
      .join(:pact_versions,
        {
          Sequel[:verifications][:pact_version_id] => Sequel[:pv][:id]
        }, { table_alias: :pv })

    create_or_replace_view(:latest_verifications_for_consumer_and_provider, latest_verifications)
  end

  down do
    drop_view(:latest_verifications_for_consumer_and_provider)
    drop_view(:latest_verification_ids_for_consumer_and_provider)
  end
end
