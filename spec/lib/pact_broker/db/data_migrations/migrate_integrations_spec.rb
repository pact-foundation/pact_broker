require "pact_broker/db/data_migrations/migrate_integrations"

module PactBroker
  module DB
    module DataMigrations
      describe MigrateIntegrations, migration: true do
        before do
          PactBroker::TestDatabase.migrate
          td.create_pact_with_hierarchy("Foo1", "1", "Bar1")
            .create_pact_with_hierarchy("Foo2", "1", "Bar2")
          PactBroker::Integrations::Integration.where(consumer_id: td.consumer.id, provider_id: td.provider.id).delete
        end

        subject { MigrateIntegrations.call(database) }

        it "inserts any missing integrations" do
          expect { subject }.to change { PactBroker::Integrations::Integration.count }.from(1).to(2)
        end
      end
    end
  end
end
