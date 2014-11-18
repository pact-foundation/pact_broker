require 'digest/sha1'
require_relative 'migration_helper'

Sequel.migration do
  change do
    create_or_replace_view(:all_pacts,
      Sequel::Model.db[:pacts].select(:pacts__id,
      :c__id___consumer_id, :c__name___consumer_name,
      :cv__id___consumer_version_id, :cv__number___consumer_version_number, :cv__order___consumer_version_order,
      :p__id___provider_id, :p__name___provider_name,
      :pvc__sha___pact_version_content_sha, :pacts__created_at, :pacts__updated_at).
      join(:versions, {:id => :version_id}, {:table_alias => :cv, implicit_qualifier: :pacts}).
      join(:pacticipants, {:id => :pacticipant_id}, {:table_alias => :c, implicit_qualifier: :cv}).
      join(:pacticipants, {:id => :provider_id}, {:table_alias => :p, implicit_qualifier: :pacts}).
      join(:pact_version_contents, {:sha => :pact_version_content_sha}, {:table_alias => :pvc, implicit_qualifier: :pacts})
    )
  end
end
