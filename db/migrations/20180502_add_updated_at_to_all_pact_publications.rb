Sequel.migration do
  up do
    create_or_replace_view(:all_pact_publications,
      Sequel::Model.db[:pact_publications].select(
      Sequel[:pact_publications][:id],
      Sequel[:c][:id].as(:consumer_id), Sequel[:c][:name].as(:consumer_name),
      Sequel[:cv][:id].as(:consumer_version_id), Sequel[:cv][:number].as(:consumer_version_number), Sequel[:cv][:order].as(:consumer_version_order),
      Sequel[:p][:id].as(:provider_id), Sequel[:p][:name].as(:provider_name),
      Sequel[:pact_publications][:revision_number], Sequel[:pv][:id].as(:pact_version_id), Sequel[:pv][:sha].as(:pact_version_sha),
      Sequel[:pact_publications][:created_at],
      Sequel[:pact_publications][:updated_at]).
      join(:versions, {:id => :consumer_version_id}, {:table_alias => :cv, implicit_qualifier: :pact_publications}).
      join(:pacticipants, {:id => :pacticipant_id}, {:table_alias => :c, implicit_qualifier: :cv}).
      join(:pacticipants, {:id => :provider_id}, {:table_alias => :p, implicit_qualifier: :pact_publications}).
      join(:pact_versions, {:id => :pact_version_id}, {:table_alias => :pv, implicit_qualifier: :pact_publications})
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
  end

  down do
    create_or_replace_view(:all_pact_publications,
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

    create_or_replace_view(:latest_pact_publications_by_consumer_versions,
      "select app.*
      from all_pact_publications app
      inner join latest_pact_publication_revision_numbers lr
      on app.consumer_id = lr.consumer_id
        and app.provider_id = lr.provider_id
        and app.consumer_version_order = lr.consumer_version_order
        and app.revision_number = lr.latest_revision_number"
        )
  end
end
