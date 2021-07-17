require "forwardable"
require "pact_broker/domain/pact"
require "pact_broker/pacts/pact_version"
require "pact_broker/repositories/helpers"
require "pact_broker/integrations/integration"
require "pact_broker/tags/head_pact_tags"
require "pact_broker/pacts/pact_publication_dataset_module"
require "pact_broker/pacts/pact_publication_wip_dataset_module"
require "pact_broker/pacts/eager_loaders"
require "pact_broker/pacts/lazy_loaders"

module PactBroker
  module Pacts
    class PactPublication < Sequel::Model(:pact_publications)

      extend Forwardable

      delegate [:consumer_version_number, :name, :provider_name, :consumer_name] => :cached_domain_for_delegation

      set_primary_key :id
      associate(:many_to_one, :provider, :class => "PactBroker::Domain::Pacticipant", :key => :provider_id, :primary_key => :id)
      associate(:many_to_one, :consumer, :class => "PactBroker::Domain::Pacticipant", :key => :consumer_id, :primary_key => :id)
      associate(:many_to_one, :consumer_version, :class => "PactBroker::Domain::Version", :key => :consumer_version_id, :primary_key => :id)
      associate(:many_to_one, :pact_version, class: "PactBroker::Pacts::PactVersion", :key => :pact_version_id, :primary_key => :id)
      associate(:many_to_one, :integration, class: "PactBroker::Integrations::Integration", key: [:consumer_id, :provider_id], primary_key: [:consumer_id, :provider_id])

      one_to_one(:latest_verification, class: "PactBroker::Domain::Verification", key: :pact_version_id, primary_key: :pact_version_id) do | ds |
        ds.unlimited.latest_by_pact_version
      end

      # TODO rename to consumer_version_tags
      associate(:one_to_many, :tags, :class => "PactBroker::Domain::Tag", :key => :version_id, :primary_key => :consumer_version_id)

      one_to_many(:head_pact_publications_for_tags,
        class: PactPublication,
        read_only: true,
        dataset: PactBroker::Pacts::LazyLoaders::HEAD_PACT_PUBLICATIONS_FOR_TAGS,
        eager_loader: PactBroker::Pacts::EagerLoaders::HeadPactPublicationsForTags
      )

      plugin :upsert, identifying_columns: [:consumer_version_id, :provider_id, :revision_number]
      plugin :timestamps, update_on_create: true

      dataset_module do
        include PactBroker::Repositories::Helpers
        include PactPublicationDatasetModule
        include PactPublicationWipDatasetModule
      end

      def self.subtract(a, *b)
        b_ids = b.flat_map{ |pact_publications| pact_publications.collect(&:id) }
        a.reject{ |pact_publication| b_ids.include?(pact_publication.id) }
      end

      def before_create
        super
        self.revision_number ||= 1
      end

      def head_pact_tags
        consumer_version.tags.select{ |tag| head_tag_names.include?(tag.name) }
      end

      # The names of the tags for which this pact is the latest pact with that tag
      # (ie. it is not necessarily the pact for the latest consumer version with the given tag)
      def head_tag_names
        @head_tag_names ||= head_pact_publications_for_tags
          .select { |head_pact_publication| head_pact_publication.id == id }
          .collect { | head_pact_publication| head_pact_publication.values.fetch(:tag_name) }
      end

      def consumer_version_tags
        tags
      end

      def latest_verification
        pact_version.latest_verification
      end

      def latest_for_branch?
        return nil unless consumer_version.branch
        self_order = self.consumer_version.order
        PactPublication.where(consumer_id: consumer_id, provider_id: provider_id)
          .join_consumer_versions(:cv, { Sequel[:cv][:branch] => consumer_version.branch} ) do
            Sequel[:cv][:order] > self_order
          end
        .empty?
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
          latest_verification: pact_version.latest_verification,
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

      # Think we really could just use the version here.
      def to_version_domain
        OpenStruct.new(
          id: consumer_version.id,
          number: consumer_version.number,
          pacticipant: consumer,
          tags: consumer_version.tags,
          order: consumer_version.order,
          branch: consumer_version.branch,
          current_deployed_versions: consumer_version.current_deployed_versions,
          current_supported_released_versions: consumer_version.current_supported_released_versions
        )
      end

      def to_version_domain_lightweight
        OpenStruct.new(
          id: consumer_version.id,
          number: consumer_version.number,
          pacticipant: consumer,
          order: consumer_version.order,
          branch: consumer_version.branch,
          current_deployed_versions: consumer_version.associations[:current_deployed_versions],
          current_supported_released_versions: consumer_version.associations[:current_supported_released_versions],
        )
      end

      def to_domain_with_content
        to_domain
      end

      def to_head_pact
        HeadPact.new(to_domain, consumer_version.number, values[:tag_name])
      end

      def pact_version_sha
        pact_version.sha
      end

      def <=> other
        self_fields = [consumer.name.downcase, provider.name.downcase, consumer_version_order || 0]
        other_fields = [other.consumer.name.downcase, other.provider.name.downcase, other.consumer_version_order || 0]
        self_fields <=> other_fields
      end

      private

      def cached_domain_for_delegation
        @domain_object ||= to_domain
      end
    end
  end
end

# Table: pact_publications
# Columns:
#  id                  | integer                     | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
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
