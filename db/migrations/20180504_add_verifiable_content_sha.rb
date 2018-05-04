Sequel.migration do
  change do
    alter_table(:pact_versions) do
      add_column(:verifiable_content_sha, String)
      #add_index([:verifiable_content_sha], '')
    end

    alter_table(:verifications) do
      add_column(:verifiable_content_sha, String, null: true)
    end

    create_or_replace_view(:all_pact_publications,
      Sequel::Model.db[:pact_publications].select(
      Sequel[:pact_publications][:id],
      Sequel[:c][:id].as(:consumer_id), Sequel[:c][:name].as(:consumer_name),
      Sequel[:cv][:id].as(:consumer_version_id), Sequel[:cv][:number].as(:consumer_version_number), Sequel[:cv][:order].as(:consumer_version_order),
      Sequel[:p][:id].as(:provider_id), Sequel[:p][:name].as(:provider_name),
      Sequel[:pact_publications][:revision_number], Sequel[:pv][:id].as(:pact_version_id),
      Sequel[:pv][:sha].as(:pact_version_sha),
      Sequel[:pact_publications][:created_at],
      Sequel[:pv][:verifiable_content_sha].as(:pact_verifiable_content_sha)).
      join(:versions, {:id => :consumer_version_id}, {:table_alias => :cv, implicit_qualifier: :pact_publications}).
      join(:pacticipants, {:id => :pacticipant_id}, {:table_alias => :c, implicit_qualifier: :cv}).
      join(:pacticipants, {:id => :provider_id}, {:table_alias => :p, implicit_qualifier: :pact_publications}).
      join(:pact_versions, {:id => :pact_version_id}, {:table_alias => :pv, implicit_qualifier: :pact_publications})
    )

  end
end
