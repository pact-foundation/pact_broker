require 'sequel'

module PactBroker
  module Repositories
    class PactRepository

      include PactBroker::Logging

      def find_by_version_and_provider version_id, provider_id
        PactBroker::Models::Pact.where(version_id: version_id, provider_id: provider_id).single_record
      end

      def find_latest_version(consumer_name, provider_name)
        PactBroker::Models::Pact.
          join(:versions, {:id => :version_id}, {implicit_qualifier: :pacts}).
          join(:pacticipants, {:id => :pacticipant_id}, {:table_alias => :consumers, implicit_qualifier: :versions}).
          join(:pacticipants, {:id => :provider_id}, {:table_alias => :providers, implicit_qualifier: :pacts}).
          where('providers.name = ?', provider_name).
          where('consumers.name = ?', consumer_name).
          order('versions.id').
          last
      end

      def create params
        PactBroker::Models::Pact.new(version_id: params[:version_id], provider_id: params[:provider_id], json_content: params[:json_content]).save
      end

      def create_or_update params
        if pact = find_by_version_and_provider(params[:version_id], params[:provider_id])
          pact.update_fields(json_content: params[:json_content])
        else
          create params
        end
      end

    end
  end
end
