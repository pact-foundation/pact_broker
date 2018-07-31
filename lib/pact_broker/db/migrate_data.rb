require 'pact_broker/db/data_migrations/set_pacticipant_ids_for_verifications'

module PactBroker
  module DB
    class MigrateData
      def self.call database_connection, options = {}
        DataMigrations::SetPacticipantIdsForVerifications.call(database_connection)
      end
    end
  end
end
