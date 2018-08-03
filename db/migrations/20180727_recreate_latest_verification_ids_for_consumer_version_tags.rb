Sequel.migration do
  up do
    ltcvo = :latest_tagged_pact_consumer_version_orders
    versions_join = {
      Sequel[ltcvo][:consumer_id] => Sequel[:cv][:pacticipant_id],
      Sequel[ltcvo][:latest_consumer_version_order] => Sequel[:cv][:order]
    }
    lpp_join = {
      Sequel[:lpp][:consumer_version_id] => Sequel[:cv][:id],
      Sequel[ltcvo][:provider_id] => Sequel[:lpp][:provider_id]
    }
    # todo add pact_version_id to latest_pact_publication_ids_by_consumer_versions?
    pp_join = {
      Sequel[:pp][:id] => Sequel[:lpp][:pact_publication_id]
    }
    verifications_join = {
      Sequel[:v][:pact_version_id] => Sequel[:pp][:pact_version_id]
    }
    view = from(ltcvo).select_group(
          Sequel[ltcvo][:provider_id],
          Sequel[ltcvo][:consumer_id],
          Sequel[ltcvo][:tag_name].as(:consumer_version_tag_name))
        .select_append{ max(v[id]).as(latest_verification_id) }
        .join(:versions, versions_join, { table_alias: :cv } )
        .join(:latest_pact_publication_ids_by_consumer_versions, lpp_join, { table_alias: :lpp })
        .join(:pact_publications, pp_join, { table_alias: :pp })
        .join(:verifications, verifications_join, { table_alias: :v })

    create_or_replace_view(:latest_verification_ids_for_consumer_version_tags, view)
  end

  down do
    # The latest verification id for each consumer version tag
    create_or_replace_view(:latest_verification_ids_for_consumer_version_tags,
      "select
        pv.pacticipant_id as provider_id,
        lpp.consumer_id,
        t.name as consumer_version_tag_name,
        max(v.id) as latest_verification_id
      from verifications v
      join latest_pact_publications_by_consumer_versions lpp
        on v.pact_version_id = lpp.pact_version_id
      join tags t
        on lpp.consumer_version_id = t.version_id
      join versions pv
        on v.provider_version_id = pv.id
      group by pv.pacticipant_id, lpp.consumer_id, t.name")
  end
end
