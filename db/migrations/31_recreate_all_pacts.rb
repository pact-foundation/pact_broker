Sequel.migration do
  up do
    create_or_replace_view(:all_pact_revisions,
      Sequel::Model.db[:pact_revisions].select(:pact_revisions__id,
      :c__id___consumer_id, :c__name___consumer_name,
      :cv__id___consumer_version_id, :cv__number___consumer_version_number, :cv__order___consumer_version_order,
      :p__id___provider_id, :p__name___provider_name,
      :pact_revisions__revision_number, :pvc__id___pact_version_content_id, :pvc__sha___pact_version_content_sha, :pact_revisions__created_at).
      join(:versions, {:id => :consumer_version_id}, {:table_alias => :cv, implicit_qualifier: :pact_revisions}).
      join(:pacticipants, {:id => :pacticipant_id}, {:table_alias => :c, implicit_qualifier: :cv}).
      join(:pacticipants, {:id => :provider_id}, {:table_alias => :p, implicit_qualifier: :pact_revisions}).
      join(:pact_version_contents, {:id => :pact_version_content_id}, {:table_alias => :pvc, implicit_qualifier: :pact_revisions})
    )

    # Latest revision number for each consumer version order
    create_or_replace_view(:latest_pact_revision_numbers,
      "select provider_id, consumer_id, consumer_version_order, max(revision_number) as latest_revision_number
      from all_pact_revisions
      group by provider_id, consumer_id, consumer_version_order"
    )

    create_or_replace_view(:all_pacts,
      "select apr.*
      from all_pact_revisions apr
      inner join latest_pact_revision_numbers lr
      on apr.consumer_id = lr.consumer_id
        and apr.provider_id = lr.provider_id
        and apr.consumer_version_order = lr.consumer_version_order
        and apr.revision_number = lr.latest_revision_number"
        )
  end
end
