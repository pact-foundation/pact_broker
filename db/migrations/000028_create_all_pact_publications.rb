Sequel.migration do
  up do
    # The denormalised pact publication details for each publication
    create_view(:all_pact_publications,
      Sequel::Model.db[:pact_publications].select(
      Sequel[:pact_publications][:id],
      Sequel[:c][:id].as(:consumer_id), Sequel[:c][:name].as(:consumer_name),
      Sequel[:cv][:id].as(:consumer_version_id), Sequel[:cv][:number].as(:consumer_version_number), Sequel[:cv][:order].as(:consumer_version_order),
      Sequel[:p][:id].as(:provider_id), Sequel[:p][:name].as(:provider_name),
      Sequel[:pact_publications][:revision_number], Sequel[:pv][:id].as(:pact_version_id), Sequel[:pv][:sha].as(:pact_version_sha), Sequel[:pact_publications][:created_at]).
      join(:versions, {:id => :consumer_version_id}, {:table_alias => :cv, implicit_qualifier: :pact_publications}).
      join(:pacticipants, {:id => :pacticipant_id}, {:table_alias => :c, implicit_qualifier: :cv}).
      join(:pacticipants, {:id => :provider_id}, {:table_alias => :p, implicit_qualifier: :pact_publications}).
      join(:pact_versions, {:id => :pact_version_id}, {:table_alias => :pv, implicit_qualifier: :pact_publications})
    )

    # Latest revision number for each consumer version order
    create_view(:latest_pact_publication_revision_numbers,
      "select provider_id, consumer_id, consumer_version_order, max(revision_number) as latest_revision_number
      from all_pact_publications
      group by provider_id, consumer_id, consumer_version_order"
    )

    # Latest pact_publication (revision) for each provider/consumer version
    # updated in 20180519_recreate_views.rb
    create_view(:latest_pact_publications_by_consumer_versions,
      "select app.*
      from all_pact_publications app
      inner join latest_pact_publication_revision_numbers lr
      on app.consumer_id = lr.consumer_id
        and app.provider_id = lr.provider_id
        and app.consumer_version_order = lr.consumer_version_order
        and app.revision_number = lr.latest_revision_number"
        )

    # updated in 20180519_recreate_views.rb
    # This view tells us the latest consumer version with a pact for a consumer/provider pair
    create_or_replace_view(:latest_pact_consumer_version_orders,
      "select provider_id, consumer_id, max(consumer_version_order) as latest_consumer_version_order
      from all_pact_publications
      group by provider_id, consumer_id"
    )

    # Latest pact publications by consumer/provider
    create_view(:latest_pact_publications,
      "select lpcv.*
      from latest_pact_publications_by_consumer_versions lpcv
      inner join latest_pact_consumer_version_orders lp
      on lpcv.consumer_id = lp.consumer_id
           and lpcv.provider_id = lp.provider_id
           and lpcv.consumer_version_order = latest_consumer_version_order"
    )

  end
end
