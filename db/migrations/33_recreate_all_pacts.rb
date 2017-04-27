Sequel.migration do
  up do
    # The denormalised pact publication details for each publication
    create_or_replace_view(:all_pact_publications,
      Sequel::Model.db[:pact_publications].select(:pact_publications__id,
      :c__id___consumer_id, :c__name___consumer_name,
      :cv__id___consumer_version_id, :cv__number___consumer_version_number, :cv__order___consumer_version_order,
      :p__id___provider_id, :p__name___provider_name,
      :pact_publications__revision_number, :pvc__sha___pact_version_sha, :pact_publications__created_at).
      join(:versions, {:id => :consumer_version_id}, {:table_alias => :cv, implicit_qualifier: :pact_publications}).
      join(:pacticipants, {:id => :pacticipant_id}, {:table_alias => :c, implicit_qualifier: :cv}).
      join(:pacticipants, {:id => :provider_id}, {:table_alias => :p, implicit_qualifier: :pact_publications}).
      join(:pact_versions, {:id => :pact_version_id}, {:table_alias => :pvc, implicit_qualifier: :pact_publications})
    )

    # Latest revision number for each consumer version order
    create_or_replace_view(:latest_pact_publication_revision_numbers,
      "select provider_id, consumer_id, consumer_version_order, max(revision_number) as latest_revision_number
      from all_pact_publications
      group by provider_id, consumer_id, consumer_version_order"
    )

    # Latest pact_publication details for each consumer version
    create_or_replace_view(:latest_pact_publications_by_consumer_versions,
      "select app.*
      from all_pact_publications app
      inner join latest_pact_publication_revision_numbers lr
      on app.consumer_id = lr.consumer_id
        and app.provider_id = lr.provider_id
        and app.consumer_version_order = lr.consumer_version_order
        and app.revision_number = lr.latest_revision_number"
        )


    create_or_replace_view(:latest_pact_consumer_version_orders,
      "select provider_id, consumer_id, max(consumer_version_order) as latest_consumer_version_order
      from all_pact_publications
      group by provider_id, consumer_id"
    )

    # Latest pact publications by consumer/provider
    create_or_replace_view(:latest_pact_publications,
      "select lpcv.*
      from latest_pact_publications_by_consumer_versions lpcv
      inner join latest_pact_consumer_version_orders lp
      on lpcv.consumer_id = lp.consumer_id
           and lpcv.provider_id = lp.provider_id
           and lpcv.consumer_version_order = latest_consumer_version_order"
    )

  end
end
