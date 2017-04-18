Sequel.migration do
  up do
    create_or_replace_view(:all_pacts,
      Sequel::Model.db[:pact_revisions].select(:pact_revisions__id,
      :c__id___consumer_id, :c__name___consumer_name,
      :cv__id___consumer_version_id, :cv__number___consumer_version_number, :cv__order___consumer_version_order,
      :p__id___provider_id, :p__name___provider_name,
      :pact_revisions__revision_number, :pvc__sha___pact_version_content_sha, :pact_revisions__created_at).
      join(:versions, {:id => :consumer_version_id}, {:table_alias => :cv, implicit_qualifier: :pact_revisions}).
      join(:pacticipants, {:id => :pacticipant_id}, {:table_alias => :c, implicit_qualifier: :cv}).
      join(:pacticipants, {:id => :provider_id}, {:table_alias => :p, implicit_qualifier: :pact_revisions}).
      join(:pact_version_contents, {:id => :pact_version_content_id}, {:table_alias => :pvc, implicit_qualifier: :pact_revisions})
    )
  end
end
