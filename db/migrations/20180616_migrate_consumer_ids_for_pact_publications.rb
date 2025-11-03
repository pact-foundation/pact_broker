
Sequel.migration do
  up do
    PactBroker::Db::DataMigrations::SetConsumerIdsForPactPublications.call(self)
  end

  down do
    from(:pact_publications).update(consumer_id: nil)
  end
end
