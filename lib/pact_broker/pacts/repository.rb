require 'sequel'
require 'pact_broker/logging'
require 'ostruct'
require 'pact_broker/pacts/database_model'
require 'pact_broker/pacts/all_pacts'

module PactBroker
  module Pacts
    class Repository

      include PactBroker::Logging

      def find_all_pacts_between consumer_name, options
        AllPacts
          .eager(:tags)
          .where(consumer_name: consumer_name, provider_name: options.fetch(:and))
          .reverse_order(:consumer_version_order)
          .all.collect(&:to_domain)
      end

      def find_by_version_and_provider version_id, provider_id
        AllPacts
          .eager(:tags)
          .where(consumer_version_id: version_id, provider_id: provider_id)
          .limit(1).collect(&:to_domain)[0]
      end

      def find_latest_pacts
        other_pact_finder.all.collect do | row |
          row_to_pact row
        end
      end

      def find_latest_pact(consumer_name, provider_name, tag = nil)
        to_domain do
          finder = pact_finder(consumer_name, provider_name)
          finder = add_tag_criteria(finder, tag) unless tag.nil?
          finder.order(:order).last
        end
      end

      def find_pact consumer_name, consumer_version, provider_name
        AllPacts
          .eager(:tags)
          .where(consumer_name: consumer_name, provider_name: provider_name, consumer_version_number: consumer_version)
          .limit(1).collect(&:to_domain_with_content)[0]
      end

      def create params
        to_domain do
          pact_version_content = PactVersionContent.new(content: params[:json_content]).save
          DatabaseModel.new(
            version_id: params[:version_id],
            provider_id: params[:provider_id],
            pact_version_content: pact_version_content,
          ).save
        end
      end

      def update id, params
        to_domain do
          DatabaseModel.find(id: id).tap do | pact |
            pact.pact_version_content.update(content: params[:json_content])
            pact.update(updated_at: pact.pact_version_content.updated_at)
          end
        end
      end

      def find_previous_pact pact
        AllPacts
          .eager(:tags)
          .where(consumer_name: pact.consumer.name, provider_name: pact.provider.name)
          .where('consumer_version_order < ?', pact.consumer_version.order)
          .reverse_order(:consumer_version_order)
          .limit(1).collect(&:to_domain)[0]
      end

      private

      def to_domain
        database_model = yield
        database_model ? database_model.to_domain : nil
      end

      def to_domains
        database_models = yield
        database_models.collect(&:to_domain)
      end

      def db
        PactBroker::Domain::Version.new.db
      end

      def pact_finder consumer_name, provider_name
        DatabaseModel.select(
            :pacts__id, :pacts__pact_version_content_id, :pacts__version_id, :pacts__provider_id,
            :pacts__created_at, :pacts__updated_at,
            :versions__number___consumer_version_number, :versions__order___consumer_version_order).
          join(:versions, {:id => :version_id}, {implicit_qualifier: :pacts}).
          join(:pacticipants, {:id => :pacticipant_id}, {:table_alias => :consumers, implicit_qualifier: :versions}).
          join(:pacticipants, {:id => :provider_id}, {:table_alias => :providers, implicit_qualifier: :pacts}).
          where('providers.name = ?', provider_name).
          where('consumers.name = ?', consumer_name)
      end

      def other_pact_finder table = :latest_pacts
        # Need to use aliases because sqlite returns row with `` in the column name,
        # mysql does not
        db[table].select(:id,
          :consumer_id___consumer_id, :consumer_name___consumer_name,
          :provider_id___provider_id, :provider_name___provider_name,
          :consumer_version_number___consumer_version_number, :consumer_version_order___consumer_version_order,
          :json_content___json_content,
          :created_at___created_at,
          :updated_at___updated_at)
      end

      def add_tag_criteria pact_finder, tag
        pact_finder.
          join(:tags, {:version_id => :id}, {implicit_qualifier: :versions}).
          where('tags.name = ?', tag)
      end

      def row_to_pact row
        # Equality fails inside Relationship.connected if using OpenStruct, can't seem to duplicate it
        # in a test though.
        consumer = Domain::Pacticipant.new(name: row[:consumer_name])
        consumer.id = row[:consumer_id]
        provider = Domain::Pacticipant.new(name: row[:provider_name])
        provider.id = row[:provider_id]
        consumer_version = OpenStruct.new(
          number: row[:consumer_version_number],
          order: row[:consumer_version_order],
          pacticipant: consumer)
        pact = Domain::Pact.new(id: row[:id],
          consumer: consumer,
          consumer_version: consumer_version,
          provider: provider,
          consumer_version_number: row[:consumer_version_number],
          json_content: row[:json_content],
          created_at: row[:created_at],
          updated_at: row[:updated_at])
      end

    end
  end
end
