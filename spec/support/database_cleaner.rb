require 'database_cleaner'
require 'support/migration_helpers'

RSpec.configure do |config|

  config.include MigrationHelpers, migration: true, data_migration: true

  config.before(:suite) do
    if defined?(::DB)
      DatabaseCleaner.strategy = :transaction
      if DB.mysql?
        DatabaseCleaner.clean_with :deletion
      else
        DatabaseCleaner.clean_with :truncation
      end
    end
  end

  config.before :each, migration: true do
    PactBroker::Database.drop_objects
  end

  config.after :each, migration: true do
    PactBroker::Database.migrate
    PactBroker::Database.truncate
  end

  config.after :each, data_migration: true do
    PactBroker::Database.truncate
  end

  config.after :all, data_migration: true do
    PactBroker::Database.migrate
    PactBroker::Database.truncate
  end

  config.before(:each) do | example |
    unless example.metadata[:no_db_clean] || example.metadata[:migration]
      DatabaseCleaner.start if defined?(::DB)
    end
  end

  config.after(:each) do | example |
    unless example.metadata[:no_db_clean] || example.metadata[:migration]
      DatabaseCleaner.clean if defined?(::DB)
    end
  end
end
