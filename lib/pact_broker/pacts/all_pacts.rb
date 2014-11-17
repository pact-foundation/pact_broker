require 'pact_broker/domain/tag'
require 'pact_broker/domain/pacticipant'
require 'pact_broker/domain/version'
require 'pact_broker/pacts/pact_version_content'

module PactBroker
  module Pacts

    class AllPacts < Sequel::Model(:all_pacts)


      set_primary_key :id
      associate(:one_to_many, :tags, :class => "PactBroker::Domain::Tag", :reciprocal => :version, :key => :version_id, :primary_key => :consumer_version_id)
      associate(:many_to_one, :pact_version_content, :key => :pact_version_content_id, :primary_key => :id)

      # dataset_module do
      #   def latest
      #     join(:latest_pact_consumer_version_orders,
      #       {
      #         consumer_id: :consumer_id,
      #         provider_id: :provider_id,
      #         latest_consumer_version_order: :consumer_version_order
      #       },
      #       {table_alias: :lp}
      #     )
      #   end
      # end

      def to_domain
        consumer = Domain::Pacticipant.new(name: consumer_name)
        consumer.id = consumer_id
        provider = Domain::Pacticipant.new(name: provider_name)
        provider.id = provider_id
        consumer_version = OpenStruct.new(
          number: consumer_version_number,
          order: consumer_version_order,
          pacticipant: consumer,
          tags: tags)
        Domain::Pact.new(id: id,
          consumer: consumer,
          consumer_version: consumer_version,
          provider: provider,
          consumer_version_number: consumer_version_number,
          created_at: created_at,
          updated_at: updated_at)
      end

      def to_domain_with_content
        to_domain.tap do | pact |
          pact.json_content = pact_version_content.content
        end
      end

    end

  end
end
