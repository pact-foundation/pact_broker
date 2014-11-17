require_relative 'migration_helper'

Sequel.migration do
  change do
    create_table(:pact_version_contents) do
      primary_key :id
      String :content, type: PactBroker::MigrationHelper.large_text_type
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    alter_table(:pacts) do
      add_foreign_key :pact_version_content_id, :pact_version_contents, null: true, foreign_key_constraint_name: 'fk_pact_version_content'
    end

    run 'insert into pact_version_contents select id, json_content, created_at, updated_at from pacts'
    run 'update pacts set pact_version_content_id = id'

    alter_table(:pacts) do
      drop_column(:json_content)
    end

    alter_table(:pacts) do
      set_column_not_null(:pact_version_content_id)
    end

    create_or_replace_view(:all_pacts,
      Sequel::Model.db[:pacts].select(:pacts__id,
      :c__id___consumer_id, :c__name___consumer_name,
      :cv__id___consumer_version_id, :cv__number___consumer_version_number, :cv__order___consumer_version_order,
      :p__id___provider_id, :p__name___provider_name,
      :pvc__content___json_content, :pacts__created_at, :pacts__updated_at).
      join(:versions, {:id => :version_id}, {:table_alias => :cv, implicit_qualifier: :pacts}).
      join(:pacticipants, {:id => :pacticipant_id}, {:table_alias => :c, implicit_qualifier: :cv}).
      join(:pacticipants, {:id => :provider_id}, {:table_alias => :p, implicit_qualifier: :pacts}).
      join(:pact_version_contents, {:id => :pact_version_content_id}, {:table_alias => :pvc, implicit_qualifier: :pacts})
    )

  end
end
