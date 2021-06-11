require_relative "migration_helper"

Sequel.migration do
  change do
    create_view(:latest_tagged_version_orders,
      PactBroker::MigrationHelper.sqlite_safe("
        select v.pacticipant_id, t.name as tag_name, max(v.order) as latest_version_order, 1 as latest
        from tags t
        inner join versions v
        on v.id = t.version_id
        group by v.pacticipant_id, t.name
      ")
    )

    create_view(:tags_with_latest_flag,
      PactBroker::MigrationHelper.sqlite_safe("
        select t.*, ltvo.latest
        from tags t
        inner join versions v
        on v.id = t.version_id
        left outer join latest_tagged_version_orders ltvo
        on t.name = ltvo.tag_name
        and v.pacticipant_id = ltvo.pacticipant_id
        and v.order = ltvo.latest_version_order
      ")
    )
  end
end
