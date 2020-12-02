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
        @cut_off_date = options[:max_age] ? (DateTime.now - options[:max_age]) : DateTime.now
        @limit = options[:limit] || 1000
      end

      def call
        require 'pact_broker/pacts/pact_publication'
        require 'pact_broker/domain/verification'

        deleted_counts = {}
        kept_counts = {}

        deleted_counts.merge!(delete_overwritten_pact_publications)
        deleted_counts.merge!(delete_overwritten_verifications)
        deleted_counts.merge!(delete_orphan_pact_versions)
        deleted_counts.merge!(delete_webhook_data)

        kept_counts[:pact_publications] = db[:pact_publications].count
        kept_counts[:verification_results] = db[:verifications].count
        kept_counts[:pact_versions] = db[:pact_versions].count
        kept_counts[:triggered_webhooks] = db[:triggered_webhooks].count

        if dry_run?
          to_keep = deleted_counts.keys.each_with_object({}) do | table_name, new_counts |
            new_counts[table_name] = kept_counts[table_name] - deleted_counts[table_name]
          end
          { toDelete: deleted_counts, toKeep: to_keep }
        else
          { deleted: deleted_counts, kept: kept_counts }
        end
      end

      private

      attr_reader :db, :options, :cut_off_date, :limit

      def dry_run?
        options[:dry_run]
      end

      def delete_webhook_data
        ids_to_keep = db[:latest_triggered_webhooks].select(:id)
        resolved_ids_to_delete = db[:triggered_webhooks]
          .where(id: ids_to_keep)
          .invert
          .where(Sequel.lit('created_at < ?', cut_off_date))
          .limit(limit)
          .collect{ |row| row[:id] }

        PactBroker::Webhooks::TriggeredWebhook.where(id: resolved_ids_to_delete).delete unless dry_run?
        { triggered_webhooks: resolved_ids_to_delete.count }
      end

      def delete_orphan_pact_versions
        referenced_pact_version_ids = db[:pact_publications].select(:pact_version_id).union(db[:verifications].select(:pact_version_id))
        pact_version_ids_to_delete = db[:pact_versions].where(id: referenced_pact_version_ids).invert.order(:id).limit(limit).collect{ |row| row[:id] }
        db[:pact_versions].where(id: pact_version_ids_to_delete).delete unless dry_run?
        { pact_versions: pact_version_ids_to_delete.count }
      end

      def delete_overwritten_pact_publications
        ids_to_keep = db[:latest_pact_publication_ids_for_consumer_versions].select(:pact_publication_id)

        resolved_ids_to_delete = db[:pact_publications]
          .where(id: ids_to_keep)
          .invert
          .where(Sequel.lit('created_at < ?', cut_off_date))
          .order(:id)
          .limit(limit)
          .collect{ |row| row[:id] }

        PactBroker::Pacts::PactPublication.where(id: resolved_ids_to_delete).delete unless dry_run?

        { pact_publications: resolved_ids_to_delete.count }
      end

      def delete_overwritten_verifications
        ids_to_keep = db[:latest_verification_id_for_pact_version_and_provider_version].select(:verification_id)
        resolved_ids_to_delete = db[:verifications]
          .where(id: ids_to_keep)
          .invert
          .where(Sequel.lit('created_at < ?', cut_off_date))
          .order(:id)
          .limit(limit)
          .collect{ |row| row[:id] }

        PactBroker::Domain::Verification.where(id: resolved_ids_to_delete).delete unless dry_run?
        { verification_results: resolved_ids_to_delete.count }
      end
    end
  end
end
