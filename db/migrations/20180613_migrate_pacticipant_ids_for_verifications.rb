
Sequel.migration do
  up do
    PactBroker::Db::DataMigrations::SetPacticipantIdsForVerifications.call(self)
  end
end
