Dir.glob(File.expand_path(File.join(__FILE__, "..", "data_migrations", "*.rb"))).sort.each do | path |
  require path
end

# Data migrations run *every* time the broker starts up, after the schema migrations.
# Their purpose is to ensure that data integrity is maintained during rolling migrations
# in architectures with multiple application instances running against the same
# database (eg. EC2 autoscaling group) where "old" data might be inserted by
# the application instance running the previous version of the code AFTER
# the schema migrations have been run on the first application instance with the
# new version of the code.

module PactBroker
  module DB
    class MigrateData
      include PactBroker::Logging

      MIGRATIONS = [
          DataMigrations::SetPacticipantIdsForVerifications,
          DataMigrations::SetConsumerIdsForPactPublications,
          DataMigrations::SetLatestVersionSequenceValue,
          DataMigrations::SetWebhooksEnabled,
          DataMigrations::DeleteDeprecatedWebhookExecutions,
          DataMigrations::SetCreatedAtForLatestPactPublications,
          DataMigrations::SetCreatedAtForLatestVerifications,
          DataMigrations::SetExtraColumnsForTags,
          DataMigrations::SetPacticipantDisplayName,
          DataMigrations::SetWebhookUuid,
          DataMigrations::SetConsumerVersionOrderForPactPublications,
          DataMigrations::CreateBranches,
          DataMigrations::MigrateIntegrations,
          DataMigrations::MigratePactVersionProviderTagSuccessfulVerifications,
          DataMigrations::SetContractDataUpdatedAtForIntegrations
      ].freeze

      def self.registered_migrations
        MIGRATIONS
      end

      def self.call database_connection, _options = {}
        registered_migrations.each do | migration |
          logger.debug "Running data migration #{migration.to_s.split("::").last.gsub(/([a-z\d])([A-Z])/, '\1 \2').split.join("-")}"
          migration.call(database_connection)
        end
      end
    end
  end
end
