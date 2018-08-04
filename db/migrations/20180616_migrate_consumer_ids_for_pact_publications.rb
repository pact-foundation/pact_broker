require 'pact_broker/db/data_migrations/set_consumer_ids_for_pact_publications'

Sequel.migration do
  up do
    PactBroker::DB::DataMigrations::SetConsumerIdsForPactPublications.call(self)
  end

  down do
    from(:pact_publications).update(consumer_id: nil)
  end
end
