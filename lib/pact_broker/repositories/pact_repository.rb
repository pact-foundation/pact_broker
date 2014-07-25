require 'sequel'
require 'pact_broker/logging'
require 'ostruct'

module PactBroker
  module Repositories
    class PactRepository

      include PactBroker::Logging

      def find_by_version_and_provider version_id, provider_id
        PactBroker::Models::Pact.where(version_id: version_id, provider_id: provider_id).single_record
      end

      def find_latest_pacts
        # Need to use aliases because sqlite returns row with `` in the column name, mysql does not
        db[:latest_pacts].select(:id, :consumer_id___cid, :consumer_name___cn, :provider_id___pid, :provider_name___pn, :consumer_version_number___cvn).all.collect do | row |
          consumer = OpenStruct.new(name: row[:cn], id: row[:cid])
          provider = OpenStruct.new(name: row[:pn], id: row[:pid])
          consumer_version = OpenStruct.new(number: row[:cvn], pacticipant: consumer)
          pact = OpenStruct.new(id: row[:id], consumer: consumer, consumer_version: consumer_version, provider: provider)
        end

      end

      def find_latest_pact(consumer_name, provider_name, tag = nil)
        finder = pact_finder(consumer_name, provider_name)
        finder = add_tag_criteria(finder, tag) unless tag.nil?
        finder.order(:order).last
      end

      def find_pact consumer_name, consumer_version, provider_name
        pact_finder(consumer_name, provider_name).where('versions.number = ?', consumer_version).single_record
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

      private

      def db
        PactBroker::Models::Version.new.db
      end

      def pact_finder consumer_name, provider_name
        PactBroker::Models::Pact.select(:pacts__id, :pacts__json_content, :pacts__version_id, :pacts__provider_id, :versions__number___consumer_version_number).
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

    end
  end
end
