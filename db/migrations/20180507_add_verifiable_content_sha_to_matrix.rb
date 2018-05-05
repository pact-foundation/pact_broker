Sequel.migration do
  up do
    p = :all_pact_publications

    verifications_join = {
      Sequel[:verifications][:pact_verifiable_content_sha] => Sequel[p][:pact_verifiable_content_sha],
      Sequel[:verifications][:consumer_id] => Sequel[p][:consumer_id],
      Sequel[:verifications][:provider_id] => Sequel[p][:provider_id],
    }

    provider_versions_join = {
      Sequel[:provider_versions][:id] => Sequel[:verifications][:provider_version_id]
    }

    view = from(p)
      .select(
        Sequel[p][:consumer_id],
        Sequel[p][:consumer_name],
        Sequel[p][:consumer_version_id],
        Sequel[p][:consumer_version_number],
        Sequel[p][:consumer_version_order],
        Sequel[p][:id].as(:pact_publication_id),
        Sequel[p][:pact_version_id],
        Sequel[p][:pact_version_sha],
        Sequel[p][:pact_verifiable_content_sha],
        Sequel[p][:revision_number].as(:pact_revision_number),
        Sequel[p][:created_at].as(:pact_created_at),
        Sequel[p][:provider_id],
        Sequel[p][:provider_name],
        Sequel[:provider_versions][:id].as(:provider_version_id),
        Sequel[:provider_versions][:number].as(:provider_version_number),
        Sequel[:provider_versions][:order].as(:provider_version_order),
        Sequel[:verifications][:id].as(:verification_id),
        Sequel[:verifications][:success],
        Sequel[:verifications][:number].as(:verification_number),
        Sequel[:verifications][:execution_date].as(:verification_executed_at),
        Sequel[:verifications][:build_url].as(:verification_build_url)
      )
      .left_outer_join(:verifications, verifications_join)
      .left_outer_join(:versions, provider_versions_join, { table_alias: :provider_versions })

    create_or_replace_view(:matrix, view)
  end

  down do
    p = :all_pact_publications
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
          Sequel[p][:revision_number].as(:pact_revision_number),
          Sequel[p][:created_at].as(:pact_created_at),
          Sequel[p][:provider_id],
          Sequel[p][:provider_name],
          Sequel[:versions][:id].as(:provider_version_id),
          Sequel[:versions][:number].as(:provider_version_number),
          Sequel[:versions][:order].as(:provider_version_order),
          Sequel[:verifications][:id].as(:verification_id),
          Sequel[:verifications][:success],
          Sequel[:verifications][:number].as(:verification_number),
          Sequel[:verifications][:execution_date].as(:verification_executed_at),
          Sequel[:verifications][:build_url].as(:verification_build_url)
        )
        .left_outer_join(:verifications, { Sequel[:verifications][:pact_version_id] => Sequel[p][:pact_version_id] })
        .left_outer_join(:versions, {Sequel[:versions][:id] => Sequel[:verifications][:provider_version_id]})
    )
  end
end
