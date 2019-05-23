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
      def self.call database_connection, options = {}
        DataMigrations::SetPacticipantIdsForVerifications.call(database_connection)
        DataMigrations::SetConsumerIdsForPactPublications.call(database_connection)
        DataMigrations::SetLatestVersionSequenceValue.call(database_connection)
        DataMigrations::SetWebhooksEnabled.call(database_connection)
      end
    end
  end
end
