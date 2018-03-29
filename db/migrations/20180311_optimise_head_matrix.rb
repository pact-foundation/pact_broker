require_relative 'migration_helper'

Sequel.migration do
  up do
    pp = :pact_publications
    # For each consumer_id/provider_id/tag_name, the version order of the latest version that has a pact
    create_or_replace_view(:latest_tagged_pact_consumer_version_orders,
      from(:pact_publications)
        .select_group(
          Sequel[pp][:provider_id],
          Sequel[:cv][:pacticipant_id].as(:consumer_id),
          Sequel[:t][:name].as(:tag_name))
        .select_append{ max(order).as(latest_consumer_version_order) }
        .join(:versions, { Sequel[pp][:consumer_version_id] => Sequel[:cv][:id] }, { table_alias: :cv} )
        .join(:tags, { Sequel[:t][:version_id] => Sequel[pp][:consumer_version_id] }, { table_alias: :t })
    )

    # Add provider_version_order to original definition
    v = :verifications
    create_or_replace_view(:latest_verifications,
      from(v)
        .select(
          Sequel[v][:id],
          Sequel[v][:number],
          Sequel[v][:success],
          Sequel[:s][:number].as(:provider_version),
          Sequel[v][:build_url],
          Sequel[v][:pact_version_id],
          Sequel[v][:execution_date],
          Sequel[v][:created_at],
          Sequel[v][:provider_version_id],
          Sequel[:s][:number].as(:provider_version_number),
          Sequel[:s][:order].as(:provider_version_order))
        .join(:latest_verification_numbers,
          {
            Sequel[v][:pact_version_id] => Sequel[:lv][:pact_version_id],
            Sequel[v][:number] => Sequel[:lv][:latest_number]
          }, { table_alias: :lv })
        .join(:versions,
          {
            Sequel[v][:provider_version_id] => Sequel[:s][:id]
          }, { table_alias: :s })
    )


    create_or_replace_view(:head_matrix,
      "
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
      "
    )
  end
end
