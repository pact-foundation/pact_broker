require 'sequel'
require 'pact_broker/project_root'

module PactBroker
  module DB
    class Clean
      def self.call database_connection, options = {}
        new(database_connection, options).call
      end

      def initialize database_connection, options = {}
        @db = database_connection
        @options = options
      end

      def call
        deleted_counts = {}
        kept_counts = {}
        date = options[:date]
        pact_publication_ids_to_delete = if date
          db[:pact_publications].select(:id).where(Sequel.lit('created_at < ?', date))
        else
          db[:pact_publications].select(:id).where(id: db[:head_matrix].select(:pact_publication_id)).invert
        end

        deleted_counts[:pact_publications] = pact_publication_ids_to_delete.count
        kept_counts[:pact_publications] = db[:pact_publications].where(id: pact_publication_ids_to_delete).invert.count

        # TODO head matrix is the head for the consumer tags, not the provider tags.
        # Work out how to keep the head verifications for the provider tags.
        verification_ids = get_verification_ids(pact_publication_ids_to_delete)
        deleted_counts[:verification_results] = verification_ids.count
        kept_counts[:verification_results] = db[:verifications].where(id:verification_ids ).invert.count

        delete_webhook_data(db[:triggered_webhooks].where(verification_id: verification_ids).select(:id))
        verification_ids.delete

        delete_webhook_data(db[:triggered_webhooks].where(pact_publication_id: pact_publication_ids_to_delete).select(:id))
        delete_deprecated_webhook_executions(pact_publication_ids_to_delete)
        delete_pact_publications(pact_publication_ids_to_delete)

        delete_orphan_pact_versions
        overwritten_delete_counts = delete_overwritten_verifications
        deleted_counts[:verification_results] = deleted_counts[:verification_results] + overwritten_delete_counts[:verification_results]
        kept_counts[:verification_results] = kept_counts[:verification_results] - overwritten_delete_counts[:verification_results]


        referenced_version_ids = db[:pact_publications].select(:consumer_version_id).collect{ | h| h[:consumer_version_id] } +
          db[:verifications].select(:provider_version_id).collect{ | h| h[:provider_version_id] }

        delete_orphan_tags(referenced_version_ids)
        delete_orphan_versions(referenced_version_ids)

        { kept: kept_counts, deleted: deleted_counts }
      end

      private

      attr_reader :db, :options

      def get_verification_ids(pact_publication_ids)
        db[:verifications].select(:id).where(pact_version_id: db[:pact_publications].select(:pact_version_id).where(id: pact_publication_ids))
      end

      def delete_webhook_data(triggered_webhook_ids)
        db[:webhook_executions].where(triggered_webhook_id: triggered_webhook_ids).delete
        db[:triggered_webhooks].where(id: triggered_webhook_ids).delete

      end

      def delete_deprecated_webhook_executions(pact_publication_ids)
        db[:webhook_executions].where(pact_publication_id: pact_publication_ids).delete
      end

      def delete_pact_publications(pact_publication_ids)
        db[:pact_publications].where(id: pact_publication_ids).delete
        db[:pact_versions].where(id: db[:pact_publications].select(:pact_version_id)).invert.delete
      end

      def delete_orphan_pact_versions
        # TODO use union
        referenced_pact_version_ids = db[:pact_publications].select(:pact_version_id).collect{ | h| h[:pact_version_id] } +
          db[:verifications].select(:pact_version_id).collect{ | h| h[:pact_version_id] }
        db[:pact_versions].where(id: referenced_pact_version_ids).invert.delete
      end

      def delete_orphan_tags(referenced_version_ids)
        db[:tags].where(version_id: referenced_version_ids).invert.delete
      end

      def delete_orphan_versions(referenced_version_ids)
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
