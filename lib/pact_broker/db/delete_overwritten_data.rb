require "date"
require "sequel"

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
        require "pact_broker/pacts/pact_publication"
        require "pact_broker/domain/verification"

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

        # TODO swap the hierarchy around so it matches the clean task

        if dry_run?
          to_keep = deleted_counts.keys.each_with_object({}) do | table_name, new_counts |
            new_counts[table_name] = kept_counts[table_name] - deleted_counts[table_name]
          end
          deleted_counts.each_with_object({}) do | (key, value), new_hash |
            new_hash[key] = { toDelete: value, toKeep: to_keep[key] }
          end
        else
          deleted_counts.each_with_object({}) do | (key, value), new_hash |
            new_hash[key] = { deleted: value, kept: kept_counts[key] }
          end
        end
      end

      private

      attr_reader :db, :options, :cut_off_date, :limit

      def dry_run?
        options[:dry_run]
      end

      def delete_webhook_data
        ltw_join = {
          Sequel[:triggered_webhooks][:id] => Sequel[:ltw][:id]
        }
        resolved_ids_to_delete =  db[:triggered_webhooks]
                                    .select(Sequel[:triggered_webhooks][:id])
                                    .left_join(:latest_triggered_webhooks, ltw_join, { table_alias: :ltw })
                                    .where(Sequel[:ltw][:id] => nil)
                                    .where(Sequel.lit("triggered_webhooks.created_at < ?", cut_off_date))
                                    .order(Sequel[:triggered_webhooks][:id])
                                    .limit(limit)
                                    .collect{ |row| row[:id] }

        PactBroker::Webhooks::TriggeredWebhook.where(id: resolved_ids_to_delete).delete unless dry_run?
        { triggered_webhooks: resolved_ids_to_delete.count }
      end

      def delete_orphan_pact_versions
        referenced_pact_version_ids = db[:pact_publications].select(:pact_version_id).union(db[:verifications].select(:pact_version_id))
        rpv_join = {
          Sequel[:pact_versions][:id] => Sequel[:rpv][:pact_version_id]
        }
        pact_version_ids_to_delete = db[:pact_versions]
                                      .select(Sequel[:pact_versions][:id])
                                      .left_join(referenced_pact_version_ids, rpv_join, { table_alias: :rpv })
                                      .where(Sequel[:rpv][:pact_version_id] => nil)
                                      .order(Sequel[:pact_versions][:id])
                                      .limit(limit)
                                      .collect{ |row| row[:id] }
        db[:pact_versions].where(id: pact_version_ids_to_delete).delete unless dry_run?
        { pact_versions: pact_version_ids_to_delete.count }
      end

      def delete_overwritten_pact_publications
        lp_join = {
          Sequel[:pact_publications][:id] => Sequel[:lp][:pact_publication_id]
        }

        resolved_ids_to_delete = db[:pact_publications]
                                  .select(Sequel[:pact_publications][:id])
                                  .left_join(:latest_pact_publication_ids_for_consumer_versions, lp_join, { table_alias: :lp })
                                  .where(Sequel[:lp][:pact_publication_id] => nil)
                                  .where(Sequel.lit("pact_publications.created_at < ?", cut_off_date))
                                  .order(:id)
                                  .limit(limit)
                                  .collect{ |row| row[:id] }

        PactBroker::Pacts::PactPublication.where(id: resolved_ids_to_delete).delete unless dry_run?
        { pact_publications: resolved_ids_to_delete.count }
      end

      def delete_overwritten_verifications
        lv_join = {
          Sequel[:verifications][:id] => Sequel[:lv][:verification_id]
        }
        resolved_ids_to_delete = db[:verifications]
                                  .select(Sequel[:verifications][:id])
                                  .left_join(:latest_verification_id_for_pact_version_and_provider_version, lv_join, { table_alias: :lv})
                                  .where(Sequel[:lv][:verification_id] => nil)
                                  .where(Sequel.lit("verifications.created_at < ?", cut_off_date))
                                  .order(Sequel[:verifications][:id])
                                  .limit(limit)
                                  .collect{ |row| row[:id] }

        PactBroker::Domain::Verification.where(id: resolved_ids_to_delete).delete unless dry_run?
        { verification_results: resolved_ids_to_delete.count }
      end
    end
  end
end
