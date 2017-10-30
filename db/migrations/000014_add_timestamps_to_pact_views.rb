Sequel.migration do
  change do
    create_or_replace_view(:all_pacts,
      Sequel::Model.db[:pacts].select(
      Sequel[:pacts][:id], Sequel[:c][:id].as(:consumer_id), Sequel[:c][:name].as(:consumer_name),
      Sequel[:cv][:number].as(:consumer_version_number), Sequel[:cv][:order].as(:consumer_version_order),
      Sequel[:p][:id].as(:provider_id), Sequel[:p][:name].as(:provider_name),
      Sequel[:pacts][:json_content], Sequel[:pacts][:created_at], Sequel[:pacts][:updated_at]).
      join(:versions, {:id => :version_id}, {:table_alias => :cv, implicit_qualifier: :pacts}).
      join(:pacticipants, {:id => :pacticipant_id}, {:table_alias => :c, implicit_qualifier: :cv}).
      join(:pacticipants, {:id => :provider_id}, {:table_alias => :p, implicit_qualifier: :pacts}))

    create_or_replace_view(:latest_pact_consumer_version_orders,
      "select provider_id, consumer_id, max(consumer_version_order) as latest_consumer_version_order
      from all_pacts
      group by provider_id, consumer_id"
    )

    create_or_replace_view(:latest_pacts,
      "select ap.*
      from all_pacts ap
      inner join latest_pact_consumer_version_orders lp
      on ap.consumer_id = lp.consumer_id
           and ap.provider_id = lp.provider_id
           and ap.consumer_version_order = latest_consumer_version_order"
    )
  end
end

