require_relative 'migration_helper'

Sequel.migration do
  up do

    # For each consumer_id/provider_id/tag_name, the version order of the latest version that has a pact
    create_or_replace_view(:latest_tagged_pact_consumer_version_orders,
      "select pp.provider_id, cv.pacticipant_id as consumer_id, t.name as tag_name, max(\"order\") as latest_consumer_version_order
        from pact_publications pp
        inner join versions cv
        on pp.consumer_version_id = cv.id
        inner join tags t
        on t.version_id = pp.consumer_version_id
        group by pp.provider_id, cv.pacticipant_id, t.name"
    )

    # Add provider_version_order
    create_or_replace_view(:latest_verifications,
      PactBroker::MigrationHelper.sqlite_safe("SELECT v.id, v.number, v.success, s.number as provider_version,
        v.build_url, v.pact_version_id, v.execution_date, v.created_at,
        v.provider_version_id, s.number as provider_version_number,
        s.order as provider_version_order
        FROM verifications v
        INNER JOIN latest_verification_numbers lv
          ON v.pact_version_id = lv.pact_version_id
          AND v.number = lv.latest_number
        INNER JOIN versions s on v.provider_version_id = s.id")
      )

    create_or_replace_view(:head_matrix,

      PactBroker::MigrationHelper.sqlite_safe("
      select
        p.consumer_id, p.consumer_name, p.consumer_version_id, p.consumer_version_number, p.consumer_version_order,
        p.id as pact_publication_id, p.pact_version_id, p.pact_version_sha, p.revision_number as pact_revision_number,
        p.created_at as pact_created_at,
        p.provider_id, p.provider_name, lv.provider_version_id, lv.provider_version_number, lv.provider_version_order,
        lv.id as verification_id, lv.success, lv.number as verification_number, lv.execution_date as verification_executed_at,
        lv.build_url as verification_build_url,
        null as consumer_version_tag_name
      from latest_pact_publications p
      left outer join latest_verifications lv
        on p.pact_version_id = lv.pact_version_id

      union all

      select
        p.consumer_id, p.consumer_name, p.consumer_version_id, p.consumer_version_number, p.consumer_version_order,
        p.id as pact_publication_id, p.pact_version_id, p.pact_version_sha, p.revision_number as pact_revision_number,
        p.created_at as pact_created_at,
        p.provider_id, p.provider_name, lv.provider_version_id, lv.provider_version_number, lv.provider_version_order,
        lv.id as verification_id, lv.success, lv.number as verification_number, lv.execution_date as verification_executed_at,
        lv.build_url as verification_build_url,
        lt.tag_name as consumer_version_tag_name
      from latest_tagged_pact_consumer_version_orders lt
      inner join latest_pact_publications_by_consumer_versions p
        on lt.consumer_id = p.consumer_id
        and lt.provider_id = p.provider_id
        and lt.latest_consumer_version_order = p.consumer_version_order
      left outer join latest_verifications lv
        on p.pact_version_id = lv.pact_version_id
      ")
    )
  end
end
