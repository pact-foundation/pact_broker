require "pact_broker/db/data_migrations/set_pacticipant_ids_for_verifications"

Sequel.migration do
  up do
    PactBroker::DB::DataMigrations::SetPacticipantIdsForVerifications.call(self)
  end
end
