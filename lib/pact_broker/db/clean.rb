require "sequel"
require "pact_broker/project_root"
require "pact_broker/pacts/latest_tagged_pact_publications"
require "pact_broker/logging"
require "pact_broker/db/clean/selector"

module PactBroker
  module DB
    class Clean
      include PactBroker::Logging

      class Unionable < Array
        def union(other)
          Unionable.new(self + other)
        end
      end

      def self.call database_connection, options = {}
        new(database_connection, options).call
      end

      def initialize database_connection, options = {}
        @db = database_connection
        @options = options
      end

      def keep
        @keep ||= if options[:keep]
                    # Could be a Matrix::UnresolvedSelector from the docker image, convert it
                    options[:keep].collect { | unknown_thing | Selector.from_hash(unknown_thing.to_hash) }
                  else
                    [Selector.new(tag: true, latest: true), Selector.new(branch: true, latest: true), Selector.new(latest: true), Selector.new(deployed: true), Selector.new(released: true)]
                  end
      end

      def resolve_ids(query, column_name = :id)
        # query
        Unionable.new(query.collect { |h| h[column_name] })
      end

      def pact_publication_ids_to_keep
        @pact_publication_ids_to_keep ||= pact_publication_ids_to_keep_for_version_ids_to_keep
                                            .union(latest_pact_publication_ids_to_keep)
                                            .union(latest_tagged_pact_publications_ids_to_keep)
      end

      def pact_publication_ids_to_keep_for_version_ids_to_keep
        @pact_publication_ids_to_keep_for_version_ids_to_keep ||= resolve_ids(db[:pact_publications].select(:id).where(consumer_version_id: version_ids_to_keep))
      end

      def latest_tagged_pact_publications_ids_to_keep
        @latest_tagged_pact_publications_ids_to_keep ||= resolve_ids(keep.select(&:tag).select(&:latest).collect do | selector |
          PactBroker::Pacts::PactPublication.select(:id).latest_by_consumer_tag_for_clean_selector(selector)
        end.reduce(&:union) || [])
      end


      def latest_pact_publication_ids_to_keep
        @latest_pact_publication_ids_to_keep ||= resolve_ids(db[:latest_pact_publications].select(:id))
      end

      def pact_publication_ids_to_delete
        @pact_publication_ids_to_delete ||= resolve_ids(db[:pact_publications].select(:id).where(id: pact_publication_ids_to_keep).invert)
      end

      # because they belong to the versions to keep
      def verification_ids_to_keep_for_version_ids_to_keep
        @verification_ids_to_keep_for_version_ids_to_keep ||= resolve_ids(db[:verifications].select(:id).where(provider_version_id: version_ids_to_keep))
      end

      def verification_ids_to_keep_because_latest_verification_for_latest_pact
        @verification_ids_to_keep_because_latest_verification ||= resolve_ids(
          db[:latest_verification_ids_for_pact_versions]
            .select(:latest_verification_id)
            .where(pact_version_id:
              db[:latest_pact_publications].select(:pact_version_id)
            ),
          :latest_verification_id
        )
      end

      def verification_ids_to_keep_for_pact_publication_ids_to_keep
        @verification_ids_to_keep_for_pact_publication_ids_to_keep ||= resolve_ids(
          db[:latest_verification_id_for_pact_version_and_provider_version]
            .select(:verification_id)
            .where(pact_version_id:
              db[:pact_publications]
                .select(:pact_version_id)
                .where(id: pact_publication_ids_to_keep_for_version_ids_to_keep)
          )
        )
      end

      def verification_ids_to_keep
        @verification_ids_to_keep ||= verification_ids_to_keep_for_version_ids_to_keep.union(verification_ids_to_keep_because_latest_verification_for_latest_pact)
      end

      def verification_ids_to_delete
        @verification_ids_to_delete ||= db[:verifications].select(:id).where(id: verification_ids_to_keep).invert
      end

      def version_ids_to_keep
        @version_ids_to_keep ||= keep.collect do | selector |
          PactBroker::Domain::Version.select(:id).for_selector(selector)
        end.reduce(&:union)
      end

      def call
        deleted_counts = {}
        kept_counts = {}

        deleted_counts[:pact_publications] = pact_publication_ids_to_delete.count
        kept_counts[:pact_publications] = pact_publication_ids_to_keep.count

        # Work out how to keep the head verifications for the provider tags.

        deleted_counts[:verification_results] = verification_ids_to_delete.count
        kept_counts[:verification_results] = verification_ids_to_keep.count

        delete_webhook_data(verification_triggered_webhook_ids_to_delete)
        delete_verifications

        delete_webhook_data(pact_publication_triggered_webhook_ids_to_delete)
        delete_pact_publications

        delete_orphan_pact_versions
        overwritten_delete_counts = delete_overwritten_verifications
        deleted_counts[:verification_results] = deleted_counts[:verification_results] + overwritten_delete_counts[:verification_results]
        kept_counts[:verification_results] = kept_counts[:verification_results] - overwritten_delete_counts[:verification_results]

        delete_orphan_tags
        delete_orphan_versions

        { kept: kept_counts, deleted: deleted_counts }
      end

      private

      attr_reader :db, :options

      def verification_triggered_webhook_ids_to_delete
        db[:triggered_webhooks].select(:id).where(verification_id: verification_ids_to_delete)
      end

      def pact_publication_triggered_webhook_ids_to_delete
        db[:triggered_webhooks].select(:id).where(pact_publication_id: pact_publication_ids_to_delete)
      end

      def referenced_version_ids
        db[:pact_publications].select(:consumer_version_id).union(db[:verifications].select(:provider_version_id))
      end

      def verification_ids_for_pact_publication_ids_to_delete
        @verification_ids_for_pact_publication_ids_to_delete ||=
          db[:verifications].select(:id).where(pact_version_id: db[:pact_publications].select(:pact_version_id).where(id: pact_publication_ids_to_delete))
      end

      def delete_webhook_data(triggered_webhook_ids)
        db[:webhook_executions].where(triggered_webhook_id: triggered_webhook_ids).delete
        db[:triggered_webhooks].where(id: triggered_webhook_ids).delete
      end

      def delete_pact_publications
        db[:pact_publications].where(id: pact_publication_ids_to_delete).delete
      end

      def delete_verifications
        db[:verifications].where(id: verification_ids_to_delete).delete
      end

      def delete_orphan_pact_versions
        referenced_pact_version_ids = db[:pact_publications].select(:pact_version_id).union(db[:verifications].select(:pact_version_id))
        db[:pact_versions].where(id: referenced_pact_version_ids).invert.delete
      end

      def delete_orphan_tags
        db[:tags].where(version_id: referenced_version_ids).invert.delete
      end

      def delete_orphan_versions
        db[:versions].where(id: referenced_version_ids).invert.delete
      end

      def delete_overwritten_verifications
        verification_ids = db[:verifications].select(:id).where(id: db[:latest_verification_id_for_pact_version_and_provider_version].select(:verification_id)).invert
        deleted_counts = { verification_results: verification_ids.count }
        delete_webhook_data(db[:triggered_webhooks].where(verification_id: verification_ids).select(:id))
        verification_ids.delete
        deleted_counts
      end
    end
  end
end
