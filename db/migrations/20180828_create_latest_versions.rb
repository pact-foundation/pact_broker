Sequel.migration do
  up do
    latest_version_orders = from(:versions)
                              .select_group(:pacticipant_id)
                              .select_append{ max(order).as(latest_version_order) }

    create_or_replace_view(:latest_version_orders, latest_version_orders)

    join = {
      Sequel[:versions][:pacticipant_id] => Sequel[:latest_version_orders][:pacticipant_id],
      Sequel[:versions][:order] => Sequel[:latest_version_orders][:latest_version_order]
    }

    latest_versions = from(:versions)
      .select(Sequel[:versions].*)
      .join(:latest_version_orders, join)

    create_or_replace_view(:latest_versions, latest_versions)
  end

  down do
    drop_view(:latest_version_orders)
    drop_view(:latest_versions)
  end
end
