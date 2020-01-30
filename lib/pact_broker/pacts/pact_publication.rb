require 'pact_broker/domain/pact'
require 'pact_broker/pacts/pact_version'
require 'pact_broker/repositories/helpers'
require 'pact_broker/integrations/integration'
require 'pact_broker/tags/head_pact_tags'

module PactBroker
  module Pacts
    class PactPublication < Sequel::Model(:pact_publications)
      UNIQUE_CONSTRAINT_KEYS = [:consumer_version_id, :provider_id, :revision_number].freeze

      extend Forwardable

      delegate [:consumer_version_number, :name, :provider_name, :consumer_name] => :cached_domain_for_delegation

      set_primary_key :id
      associate(:many_to_one, :provider, :class => "PactBroker::Domain::Pacticipant", :key => :provider_id, :primary_key => :id)
      associate(:many_to_one, :consumer, :class => "PactBroker::Domain::Pacticipant", :key => :consumer_id, :primary_key => :id)
      associate(:many_to_one, :consumer_version, :class => "PactBroker::Domain::Version", :key => :consumer_version_id, :primary_key => :id)
      associate(:many_to_one, :pact_version, class: "PactBroker::Pacts::PactVersion", :key => :pact_version_id, :primary_key => :id)
      associate(:many_to_one, :integration, class: "PactBroker::Integrations::Integration", key: [:consumer_id, :provider_id], primary_key: [:consumer_id, :provider_id])
      one_to_one(:latest_verification, class: "PactBroker::Verifications::LatestVerificationForPactVersion", key: :pact_version_id, primary_key: :pact_version_id)
      one_to_many(:head_pact_tags, class: "PactBroker::Tags::HeadPactTag", primary_key: :id, key: :pact_publication_id)

      dataset_module do
        include PactBroker::Repositories::Helpers

        def remove_overridden_revisions
          join(:latest_pact_publication_ids_for_consumer_versions, { Sequel[:lp][:pact_publication_id] => Sequel[:pact_publications][:id] }, { table_alias: :lp})
        end

        def join_consumer_versions(table_alias = :cv)
          join(:versions, { Sequel[:pact_publications][:consumer_version_id] => Sequel[table_alias][:id] }, { table_alias: table_alias })
        end

        def join_consumer_version_tags(table_alias = :ct)
          join(:tags, { Sequel[table_alias][:version_id] => Sequel[:pact_publications][:consumer_version_id]}, { table_alias: table_alias })
        end

        def join_consumer_version_tags_with_names(consumer_version_tag_names)
          join(:tags, {
            Sequel[:ct][:version_id] => Sequel[:pact_publications][:consumer_version_id],
            Sequel[:ct][:name] => consumer_version_tag_names
          }, {
            table_alias: :ct
          })
        end

        def join_providers(table_alias = :providers)
          join(:pacticipants, { Sequel[:pact_publications][:provider_id] => Sequel[table_alias][:id] }, { table_alias: table_alias })
        end

        def join_consumers(table_alias = :consumers)
          join(:pacticipants, { Sequel[:pact_publications][:consumer_id] => Sequel[table_alias][:id] }, { table_alias: table_alias })
        end

        def join_pact_versions
          join(:pact_versions, { Sequel[:pact_publications][:pact_version_id] => Sequel[:pact_versions][:id] })
        end

        def eager_load_pact_versions
          eager(:pact_versions)
        end

        def tag tag_name
          filter = name_like(Sequel.qualify(:tags, :name), tag_name)
          join(:tags, {version_id: :consumer_version_id}).where(filter)
        end

        def provider_name_like(name)
          where(name_like(Sequel[:providers][:name], name))
        end

        def consumer_version_tag(tag)
          where(Sequel[:ct][:name] => tag)
        end

        def order_by_consumer_name
          order_append_ignore_case(Sequel[:consumers][:name])
        end

        def order_by_consumer_version_order
          order_append(Sequel[:cv][:order])
        end
      end

      def before_create
        super
        self.revision_number ||= 1
      end

      # The names of the tags for which this pact is the latest pact with that tag
      # (ie. it is not necessarily the pact for the latest consumer version with the given tag)
      def head_tag_names
        LatestTaggedPactPublications.where(id: id).select(:tag_name).collect{|t| t[:tag_name]}
      end

      def consumer_version_tags
        consumer_version.tags
      end

      def latest_verification
        pact_version.latest_verification
      end

      def to_domain
        PactBroker::Domain::Pact.new(
          id: id,
          provider: provider,
          consumer: consumer,
          consumer_version_number: consumer_version.number,
          consumer_version: to_version_domain,
          revision_number: revision_number,
          json_content: pact_version.content,
          pact_version_sha: pact_version.sha,
          latest_verification: nil,
          created_at: created_at,
          head_tag_names: [],
          db_model: self
          )
      end

      def to_domain_lightweight
        PactBroker::Domain::Pact.new(
          id: id,
          provider: provider,
          consumer: consumer,
          consumer_version_number: consumer_version.number,
          consumer_version: to_version_domain_lightweight,
          revision_number: revision_number,
          pact_version_sha: pact_version.sha,
          created_at: created_at,
          db_model: self
          )
      end

      def to_version_domain
        OpenStruct.new(number: consumer_version.number, pacticipant: consumer, tags: consumer_version.tags, order: consumer_version.order)
      end

      def to_version_domain_lightweight
        OpenStruct.new(number: consumer_version.number, pacticipant: consumer, order: consumer_version.order)
      end

      def upsert
        params = to_hash.merge(created_at: Sequel.datetime_class.now)
        self.id = PactPublication.upsert(params, UNIQUE_CONSTRAINT_KEYS).id
        self.refresh
      end

      private

      def cached_domain_for_delegation
        @domain_object ||= to_domain
      end
    end

    PactPublication.plugin :timestamps, update_on_create: true
  end
end

# Table: pact_publications
# Columns:
#  id                  | integer                     | PRIMARY KEY DEFAULT nextval('pact_publications_id_seq'::regclass)
#  consumer_version_id | integer                     | NOT NULL
#  provider_id         | integer                     | NOT NULL
#  revision_number     | integer                     | NOT NULL
#  pact_version_id     | integer                     | NOT NULL
#  created_at          | timestamp without time zone | NOT NULL
#  consumer_id         | integer                     |
# Indexes:
#  pact_publications_pkey              | PRIMARY KEY btree (id)
#  cv_prov_revision_unq                | UNIQUE btree (consumer_version_id, provider_id, revision_number)
#  cv_prov_id_ndx                      | btree (consumer_version_id, provider_id, id)
#  pact_publications_consumer_id_index | btree (consumer_id)
# Foreign key constraints:
#  pact_publications_consumer_id_fkey         | (consumer_id) REFERENCES pacticipants(id)
#  pact_publications_consumer_version_id_fkey | (consumer_version_id) REFERENCES versions(id)
#  pact_publications_pact_version_id_fkey     | (pact_version_id) REFERENCES pact_versions(id)
#  pact_publications_provider_id_fkey         | (provider_id) REFERENCES pacticipants(id)
# Referenced By:
#  webhook_executions                                | webhook_executions_pact_publication_id_fkey                     | (pact_publication_id) REFERENCES pact_publications(id)
#  triggered_webhooks                                | triggered_webhooks_pact_publication_id_fkey                     | (pact_publication_id) REFERENCES pact_publications(id)
#  latest_pact_publication_ids_for_consumer_versions | latest_pact_publication_ids_for_consum_pact_publication_id_fkey | (pact_publication_id) REFERENCES pact_publications(id) ON DELETE CASCADE
