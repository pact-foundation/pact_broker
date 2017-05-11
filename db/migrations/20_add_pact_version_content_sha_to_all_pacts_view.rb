require 'digest/sha1'
require_relative 'migration_helper'

Sequel.migration do
  change do
    create_or_replace_view(:all_pacts,
        Sequel::Model.db[:pacts].select(
        Sequel[:pacts][:id],
        Sequel[:c][:id].as(:consumer_id), Sequel[:c][:name].as(:consumer_name),
        Sequel[:cv][:id].as(:consumer_version_id), Sequel[:cv][:number].as(:consumer_version_number), Sequel[:cv][:order].as(:consumer_version_order),
        Sequel[:p][:id].as(:provider_id), Sequel[:p][:name].as(:provider_name),
        Sequel[:pvc][:sha].as(:pact_version_content_sha), Sequel[:pacts][:created_at], Sequel[:pacts][:updated_at]).
        join(:versions, {:id => :version_id}, {:table_alias => :cv, implicit_qualifier: :pacts}).
        join(:pacticipants, {:id => :pacticipant_id}, {:table_alias => :c, implicit_qualifier: :cv}).
        join(:pacticipants, {:id => :provider_id}, {:table_alias => :p, implicit_qualifier: :pacts}).
        join(:pact_version_contents, {:sha => :pact_version_content_sha}, {:table_alias => :pvc, implicit_qualifier: :pacts})
      )

  end
end
