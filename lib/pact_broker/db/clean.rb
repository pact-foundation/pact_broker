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
        # TODO head matrix is the head for the consumer tags, not the provider tags.
        # Work out how to keep the head verifications for the provider tags.
        verification_ids = db[:verifications].where(id: db[:head_matrix].select(:verification_id)).invert.select(:verification_id)

        triggered_webhook_ids = db[:triggered_webhooks].where(verification_id: verification_ids).select(:id)
        db[:webhook_executions].where(triggered_webhook_id: triggered_webhook_ids).delete
        db[:triggered_webhooks].where(id: triggered_webhook_ids).delete

        verification_ids.delete

        pp_ids = db[:head_matrix].select(:pact_publication_id)

        triggered_webhook_ids = db[:triggered_webhooks].where(pact_publication_id: pp_ids).invert.select(:id)
        db[:webhook_executions].where(triggered_webhook_id: triggered_webhook_ids).delete
        db[:triggered_webhooks].where(id: triggered_webhook_ids).delete
        db[:webhook_executions].where(pact_publication_id: pp_ids).invert.delete

        db[:pact_publications].where(id: pp_ids).invert.delete

        referenced_pact_version_ids = db[:pact_publications].select(:pact_version_id).collect{ | h| h[:pact_version_id] } +
          db[:verifications].select(:pact_version_id).collect{ | h| h[:pact_version_id] }
        db[:pact_versions].where(id: referenced_pact_version_ids).invert.delete

        referenced_version_ids = db[:pact_publications].select(:consumer_version_id).collect{ | h| h[:consumer_version_id] } +
          db[:verifications].select(:provider_version_id).collect{ | h| h[:provider_version_id] }

        db[:tags].where(version_id: referenced_version_ids).invert.delete
        db[:versions].where(id: referenced_version_ids).invert.delete
      end

      private

      attr_reader :db

    end
  end
end
