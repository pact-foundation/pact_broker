require 'pact_broker/domain/tag'
require 'pact_broker/domain/pacticipant'
require 'pact_broker/domain/version'
require 'pact_broker/pacts/pact_version'
require 'pact_broker/repositories/helpers'

module PactBroker
  module Pacts
    class AllPactPublications < Sequel::Model(:all_pact_publications)

      extend Forwardable

      def_delegators :cached_domain, :name

      set_primary_key :id
      associate(:one_to_many, :tags, :class => "PactBroker::Domain::Tag", :reciprocal => :version, :key => :version_id, :primary_key => :consumer_version_id)
      associate(:many_to_one, :pact_version, :key => :pact_version_id, :primary_key => :id)
      associate(:many_to_one, :latest_verification, :class => "PactBroker::Verifications::LatestVerificationForPactVersion", key: :pact_version_id, primary_key: :pact_version_id)

      dataset_module do
        include PactBroker::Repositories::Helpers

        def consumer consumer_name
          where(name_like(:consumer_name, consumer_name))
        end

        def provider provider_name
          where(name_like(:provider_name, provider_name))
        end

        # must be exactly correct names
        def pacticipants pacticipant_1, pacticipant_2
          where(
            consumer_name: pacticipant_1,
            provider_name: pacticipant_2
          ).or(
            consumer_name: pacticipant_2,
            provider_name: pacticipant_1
          )
        end

        def tag tag_name
          filter = name_like(Sequel.qualify(:tags, :name), tag_name)
          join(:tags, {version_id: :consumer_version_id}).where(filter)
        end

        def untagged
          left_outer_join(:tags, {version_id: :consumer_version_id})
            .where(Sequel.qualify(:tags, :name) => nil)
        end

        def consumer_version_number number
          where(name_like(:consumer_version_number, number))
        end

        def revision_number number
          where(revision_number: number)
        end

        def pact_version_sha sha
          where(pact_version_sha: sha)
        end

        def consumer_version_order_before order
          where(Sequel.lit("consumer_version_order < ?", order))
        end

        def consumer_version_order_after order
          where(Sequel.lit("consumer_version_order > ?", order))
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
        domain.consumer_version.tags = tags.sort
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
          tags: nil
        )
        Domain::Pact.new(
          id: id,
          consumer: consumer,
          consumer_version: consumer_version,
          provider: provider,
          consumer_version_number: consumer_version_number,
          revision_number: revision_number,
          pact_version_sha: pact_version_sha,
          created_at: created_at,
          head_tag_names: head_tag_names,
          latest_verification: pact_version.latest_verification,
          db_model: self
        )
      end

      def head_tag_names
        # Avoid circular dependency
        require 'pact_broker/pacts/latest_tagged_pact_publications'
        @head_tag_names ||= LatestTaggedPactPublications.where(id: id).select(:tag_name).collect{|t| t[:tag_name]}
      end

      def to_domain_with_content
        to_domain.tap do | pact |
          pact.json_content = pact_version.content
        end
      end

      private

      def cached_domain
        @cached_domain ||= to_domain
      end

    end

  end
end

# Table: all_pact_publications
# Columns:
#  id                      | integer                     |
#  consumer_id             | integer                     |
#  consumer_name           | text                        |
#  consumer_version_id     | integer                     |
#  consumer_version_number | text                        |
#  consumer_version_order  | integer                     |
#  provider_id             | integer                     |
#  provider_name           | text                        |
#  revision_number         | integer                     |
#  pact_version_id         | integer                     |
#  pact_version_sha        | text                        |
#  created_at              | timestamp without time zone |
