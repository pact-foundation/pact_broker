require 'sequel'
require 'pact_broker/logging'
require 'ostruct'
require 'pact_broker/repositories/pact'

module PactBroker
  module Repositories
    class PactRepository

      include PactBroker::Logging

      def find_all_pacts_between consumer_name, options
        pact_finder(consumer_name, options.fetch(:and))
          .left_outer_join(:tags, {:version_id => :id}, {implicit_qualifier: :versions})
          .reverse_order(:order).collect(&:to_model)
      end

      def find_by_version_and_provider version_id, provider_id
        PactBroker::Repositories::Pact.where(version_id: version_id, provider_id: provider_id).single_record.to_model
      end

      def find_latest_pacts
        # Need to use aliases because sqlite returns row with `` in the column name, mysql does not
        db[:latest_pacts].select(:id,
          :consumer_id___consumer_id, :consumer_name___consumer_name,
          :provider_id___provider_id, :provider_name___provider_name,
          :consumer_version_number___consumer_version_number).all.collect do | row |
          row_to_pact row
        end

      end

      def find_latest_pact(consumer_name, provider_name, tag = nil)
        finder = pact_finder(consumer_name, provider_name)
        finder = add_tag_criteria(finder, tag) unless tag.nil?
        finder.order(:order).last.to_model
      end

      def find_pact consumer_name, consumer_version, provider_name
        pact_finder(consumer_name, provider_name).where('versions.number = ?', consumer_version).single_record.to_model
      end

      def create params
        db_pact = Pact.new(version_id: params[:version_id], provider_id: params[:provider_id], json_content: params[:json_content]).save
        db_pact.to_model
      end

      def create_or_update params
        if pact = find_by_version_and_provider(params[:version_id], params[:provider_id])
          pact.update_fields(json_content: params[:json_content]).to_model
        else
          create params
        end
      end

      def find_previous_pact pact
        previous_pact = db[:all_pacts].where(:consumer_id => pact.consumer.id, :provider_id => pact.provider.id).where('consumer_version_order < ?', pact.consumer_version.order).order(:consumer_version_order).last
        previous_pact ? row_to_pact(previous_pact) : nil
      end

      private

      def db
        PactBroker::Models::Version.new.db
      end

      def pact_finder consumer_name, provider_name
        PactBroker::Repositories::Pact.select(
            :pacts__id, :pacts__json_content, :pacts__version_id, :pacts__provider_id, :pacts__created_at, :pacts__updated_at,
            :versions__number___consumer_version_number).
          join(:versions, {:id => :version_id}, {implicit_qualifier: :pacts}).
          join(:pacticipants, {:id => :pacticipant_id}, {:table_alias => :consumers, implicit_qualifier: :versions}).
          join(:pacticipants, {:id => :provider_id}, {:table_alias => :providers, implicit_qualifier: :pacts}).
          where('providers.name = ?', provider_name).
          where('consumers.name = ?', consumer_name)
      end

      def add_tag_criteria pact_finder, tag
        pact_finder.
          join(:tags, {:version_id => :id}, {implicit_qualifier: :versions}).
          where('tags.name = ?', tag)
      end

      def row_to_pact row
        # Equality fails inside Relationship.connected if using OpenStruct, can't seem to duplicate it
        # in a test though.
        consumer = Models::Pacticipant.new(name: row[:consumer_name])
        consumer.id = row[:consumer_id]
        provider = Models::Pacticipant.new(name: row[:provider_name])
        provider.id = row[:provider_id]
        consumer_version = OpenStruct.new(number: row[:consumer_version_number], pacticipant: consumer)
        pact = Models::Pact.new(id: row[:id], consumer: consumer, consumer_version: consumer_version, provider: provider, consumer_version_number: row[:consumer_version_number])
      end

    end
  end
end
