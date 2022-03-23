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
require "pact_broker/pacts/pact_publication_clean_selector_dataset_module"
require "pact_broker/pacts/head_pact"

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
      associate(:many_to_one, :integration, class: "PactBroker::Integrations::Integration", key: [:consumer_id, :provider_id], primary_key: [:consumer_id, :provider_id], read_only: true, forbid_lazy_load: false)
      # TODO rename to consumer_version_tags
      associate(:one_to_many, :tags, :class => "PactBroker::Domain::Tag", :key => :version_id, :primary_key => :consumer_version_id)

      many_to_one(:latest_verification_for_consumer_branches,
        class: "PactBroker::Domain::Verification",
        read_only: true,
        key: :id,
        primary_key: :id,
        forbid_lazy_load: false,
        dataset: PactBroker::Pacts::LazyLoaders::LATEST_VERIFICATION_FOR_CONSUMER_BRANCHES,
        eager_loader: proc do | _ |
          raise NotImplementedError
        end
      )

      one_to_many(:head_pact_publications_for_tags,
        class: PactPublication,
        read_only: true,
        dataset: PactBroker::Pacts::LazyLoaders::HEAD_PACT_PUBLICATIONS_FOR_TAGS,
        eager_loader: PactBroker::Pacts::EagerLoaders::HeadPactPublicationsForTags,
        forbid_lazy_load: false
      )

      plugin :upsert, identifying_columns: [:consumer_version_id, :provider_id, :revision_number]
      plugin :timestamps, update_on_create: true

      dataset_module do
        include PactBroker::Repositories::Helpers
        include PactPublicationDatasetModule
        include PactPublicationCleanSelectorDatasetModule
        include PactPublicationWipDatasetModule

        def eager_for_domain_with_content
          eager(:tags, :consumer, :provider, :consumer_version, :pact_version)
        end
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

      # If the consumer_version is already loaded, and it already has tags, use those
      # otherwise, load them directly.
      def consumer_version_tags
        if associations[:consumer_version] && associations[:consumer_version].associations[:tags]
          consumer_version.tags
        else
          tags
        end
      end

      def latest_verification
        pact_version.latest_verification
      end

      def latest_main_branch_verification
        pact_version.latest_main_branch_verification
      end

      def latest_for_branch?
        if !defined?(@latest_for_branch)
          if consumer_version.branch_versions.empty?
            @latest_for_branch = nil
          else
            self_order = self.consumer_version.order
            @latest_for_branch = consumer_version.branch_versions.any? do | branch_version |
              branch_versions_join = {
                Sequel[:cv][:id] => Sequel[:branch_versions][:version_id],
                Sequel[:branch_versions][:branch_name] => branch_version.branch_name
              }
              PactPublication.where(consumer_id: consumer_id, provider_id: provider_id)
                .join_consumer_versions(:cv) do
                  Sequel[:cv][:order] > self_order
                end
                .join(:branch_versions, branch_versions_join)
              .empty?
            end
          end
        end
        @latest_for_branch
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
        consumer_version
      end

      def to_version_domain_lightweight
        consumer_version
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
#  id                     | integer                     | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  consumer_version_id    | integer                     | NOT NULL
#  provider_id            | integer                     | NOT NULL
#  revision_number        | integer                     | NOT NULL
#  pact_version_id        | integer                     | NOT NULL
#  created_at             | timestamp without time zone | NOT NULL
#  consumer_id            | integer                     |
#  consumer_version_order | integer                     |
# Indexes:
#  pact_publications_pkey              | PRIMARY KEY btree (id)
#  cv_prov_revision_unq                | UNIQUE btree (consumer_version_id, provider_id, revision_number)
#  cv_prov_id_ndx                      | btree (consumer_version_id, provider_id, id)
#  pact_publications_cid_pid_cvo_index | btree (consumer_id, provider_id, consumer_version_order)
#  pact_publications_consumer_id_index | btree (consumer_id)
# Foreign key constraints:
#  pact_publications_consumer_id_fkey         | (consumer_id) REFERENCES pacticipants(id)
#  pact_publications_consumer_version_id_fkey | (consumer_version_id) REFERENCES versions(id)
#  pact_publications_pact_version_id_fkey     | (pact_version_id) REFERENCES pact_versions(id)
#  pact_publications_provider_id_fkey         | (provider_id) REFERENCES pacticipants(id)
# Referenced By:
#  latest_pact_publication_ids_for_consumer_versions | latest_pact_publication_ids_for_consum_pact_publication_id_fkey | (pact_publication_id) REFERENCES pact_publications(id) ON DELETE CASCADE
#  triggered_webhooks                                | triggered_webhooks_pact_publication_id_fkey                     | (pact_publication_id) REFERENCES pact_publications(id)
#  webhook_executions                                | webhook_executions_pact_publication_id_fkey                     | (pact_publication_id) REFERENCES pact_publications(id)
