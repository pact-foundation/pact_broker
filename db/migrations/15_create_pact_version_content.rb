require 'digest/sha1'
require_relative 'migration_helper'

Sequel.migration do
  change do
    create_table(:pact_version_contents) do
      String :sha, primary_key: true, primary_key_constraint_name: 'pk_pact_version_contents'
      String :content, type: PactBroker::MigrationHelper.large_text_type
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    alter_table(:pacts) do
      add_foreign_key :pact_version_content_sha, :pact_version_contents, null: true, foreign_key_constraint_name: 'fk_pact_version_content'
    end

    self[:pacts].each do | row |
      sha = Digest::SHA1.hexdigest(row[:json_content])
      self[:pact_version_contents].insert(sha: sha, content: row[:json_content], created_at: row[:created_at], updated_at: row[:updated_at])
      self[:pacts].where(id: row[:id]).update(pact_version_content_sha: sha)
    end

    alter_table(:pacts) do
      drop_column(:json_content)
    end

    alter_table(:pacts) do
      set_column_not_null(:pact_version_content_sha)
    end

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
