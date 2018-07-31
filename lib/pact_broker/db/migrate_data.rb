Dir.glob(File.expand_path(File.join(__FILE__, "..", "data_migrations", "*.rb"))).sort.each do | path |
  require path
end

module PactBroker
  module DB
    class MigrateData
      def self.call database_connection, options = {}
        DataMigrations::SetPacticipantIdsForVerifications.call(database_connection)
        DataMigrations::SetConsumerIdsForPactPublications.call(database_connection)
      end
    end
  end
end
