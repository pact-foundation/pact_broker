require 'pact_broker/db/data_migrations/20180501'

module PactBroker
  module DB
    module DataMigrations
      class Run
        def self.call(connection)
          PactBroker::DB::DataMigrations::Migration20180501.call(connection)
        end
      end
    end
  end
end
