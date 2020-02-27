require 'date'
require 'sequel'

module PactBroker
  module DB
    class DeleteOverwrittenData
      def self.call database_connection, options = {}
        new(database_connection, options).call
      end

      def initialize database_connection, options = {}
        @db = database_connection
        @options = options
        @before = options[:before] || DateTime.now
      end

      def call
        deleted_counts = {}
        kept_counts = {}


        deleted_counts.merge!(delete_overwritten_pact_publications)
        deleted_counts.merge!(delete_overwritten_verifications)
        deleted_counts.merge!(delete_orphan_pact_versions)

        kept_counts[:pact_publications] = db[:pact_publications].count
        kept_counts[:verification_results] = db[:verifications].count
        kept_counts[:pact_versions] = db[:pact_versions].count


        { deleted: deleted_counts, kept: kept_counts }
      end

      private

      attr_reader :db, :options, :before

      def delete_webhook_data(triggered_webhook_ids)
        db[:webhook_executions].where(triggered_webhook_id: triggered_webhook_ids).delete
        db[:triggered_webhooks].where(id: triggered_webhook_ids).delete
      end

      def delete_orphan_pact_versions
        referenced_pact_version_ids = db[:pact_publications].select(:pact_version_id).union(db[:verifications].select(:pact_version_id))
        pact_version_ids_to_delete = db[:pact_versions].where(id: referenced_pact_version_ids).invert
        deleted_counts = { pact_versions: pact_version_ids_to_delete.count }
        pact_version_ids_to_delete.delete
        deleted_counts
      end

      def delete_overwritten_pact_publications
        pact_publication_ids_to_delete = db[:pact_publications]
          .select(:id)
          .where(id: db[:latest_pact_publication_ids_for_consumer_versions].select(:pact_publication_id))
          .invert
          .where(Sequel.lit('created_at < ?', before))

        deleted_counts = { pact_publications: pact_publication_ids_to_delete.count }
        delete_webhook_data(db[:triggered_webhooks].where(pact_publication_id: pact_publication_ids_to_delete).select(:id))
        pact_publication_ids_to_delete.delete
        deleted_counts
      end

      def delete_overwritten_verifications
        verification_ids = db[:verifications].select(:id)
          .where(id: db[:latest_verification_id_for_pact_version_and_provider_version].select(:verification_id))
          .invert
          .where(Sequel.lit('created_at < ?', before))
        deleted_counts = { verification_results: verification_ids.count }
        delete_webhook_data(db[:triggered_webhooks].where(verification_id: verification_ids).select(:id))
        verification_ids.delete
        deleted_counts
      end
    end
  end
end
