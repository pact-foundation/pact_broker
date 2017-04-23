require 'pact_broker/domain/tag'
require 'pact_broker/domain/pacticipant'
require 'pact_broker/domain/version'
require 'pact_broker/pacts/pact_version'
require 'pact_broker/repositories/helpers'

module PactBroker
  module Pacts

    class AllPactPublications < Sequel::Model(:all_pact_publications)

      set_primary_key :id
      associate(:one_to_many, :tags, :class => "PactBroker::Domain::Tag", :reciprocal => :version, :key => :version_id, :primary_key => :consumer_version_id)
      associate(:many_to_one, :pact_version, :key => :pact_version_sha, :primary_key => :sha)

      dataset_module do
        include PactBroker::Repositories::Helpers

        def consumer consumer_name
          where(name_like(:consumer_name, consumer_name))
        end

        def provider provider_name
          where(name_like(:provider_name, provider_name))
        end

        def tag tag_name
          filter = name_like(Sequel.qualify(:tags, :name), tag_name)
          join(:tags, {version_id: :consumer_version_id}).where(filter)
        end

        def consumer_version_number number
          where(name_like(:consumer_version_number, number))
        end

        def consumer_version_order_before order
          where('consumer_version_order < ?', order)
        end

        def consumer_version_order_after order
          where('consumer_version_order > ?', order)
        end

        def latest
          reverse_order(:consumer_version_order).limit(1)
        end

        def earliest
          order(:consumer_version_order).limit(1)
        end
      end

      def to_domain
        domain = to_domain_without_tags
        domain.consumer_version.tags = tags
        domain
      end

      def to_domain_without_tags
        consumer = Domain::Pacticipant.new(name: consumer_name)
        consumer.id = consumer_id
        provider = Domain::Pacticipant.new(name: provider_name)
        provider.id = provider_id
        consumer_version = OpenStruct.new(
          number: consumer_version_number,
          order: consumer_version_order,
          pacticipant: consumer,
          tags: nil)
        Domain::Pact.new(id: id,
          consumer: consumer,
          consumer_version: consumer_version,
          provider: provider,
          consumer_version_number: consumer_version_number,
          revision_number: revision_number,
          created_at: created_at)
      end

      def to_domain_with_content
        to_domain.tap do | pact |
          pact.json_content = pact_version.content
        end
      end

    end

  end
end
