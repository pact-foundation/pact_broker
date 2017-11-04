Sequel.migration do
  up do
    p = :latest_pact_publications_by_consumer_versions
    create_view(:matrix,
      from(p)
        .select(
          Sequel[p][:consumer_id],
          Sequel[p][:consumer_name],
          Sequel[p][:consumer_version_id],
          Sequel[p][:consumer_version_number],
          Sequel[p][:consumer_version_order],
          Sequel[p][:id].as(:pact_publication_id),
          Sequel[p][:pact_version_id],
          Sequel[p][:pact_version_sha],
          Sequel[p][:revision_number],
          Sequel[p][:created_at].as(:pact_created_at),
          Sequel[p][:provider_id],
          Sequel[p][:provider_name],
          Sequel[:versions][:id].as(:provider_version_id),
          Sequel[:versions][:number].as(:provider_version_number),
          Sequel[:versions][:order].as(:provider_version_order),
          Sequel[:verifications][:success],
          Sequel[:verifications][:number],
          Sequel[:verifications][:id].as(:verification_id),
          Sequel[:verifications][:execution_date].as(:verification_executed_at),
          Sequel[:verifications][:build_url].as(:verification_build_url)
        )
        .left_outer_join(:verifications, { Sequel[:verifications][:pact_version_id] => Sequel[p][:pact_version_id] })
        .left_outer_join(:versions, {Sequel[:versions][:id] => Sequel[:verifications][:provider_version_id]})
    )
  end

  down do
    drop_view(:matrix)
  end
end
