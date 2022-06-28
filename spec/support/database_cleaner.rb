require "database_cleaner"
require "support/migration_helpers"

RSpec.configure do |config|

  config.include MigrationHelpers, migration: true, data_migration: true

  config.before(:suite) do
    if defined?(::PactBroker::TestDatabase)
      DatabaseCleaner.strategy = :transaction
      PactBroker::TestDatabase.truncate
    end
  end

  config.before :each, migration: true do
    PactBroker::TestDatabase.drop_objects
  end

  config.after :each, migration: true do
    PactBroker::TestDatabase.migrate
    PactBroker::TestDatabase.truncate
  end

  config.after :each, data_migration: true do
    PactBroker::TestDatabase.truncate
  end

  config.after :all, data_migration: true do
    PactBroker::TestDatabase.migrate
    PactBroker::TestDatabase.truncate
  end

  config.before(:each) do | example |
    unless example.metadata[:no_db_clean] || example.metadata[:migration]
      DatabaseCleaner.start if defined?(::PactBroker::TestDatabase)
    end
  end

  config.after(:each) do | example |
    unless example.metadata[:no_db_clean] || example.metadata[:migration]
      DatabaseCleaner.clean if defined?(::PactBroker::TestDatabase)
    end
  end
end
