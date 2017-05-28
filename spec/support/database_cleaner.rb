require 'database_cleaner'

RSpec.configure do |config|
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

  config.before(:each) do | example |
    unless example.metadata[:no_db_clean]
      DatabaseCleaner.start if defined?(::DB)
    end
  end

  config.after(:each) do | example |
    unless example.metadata[:no_db_clean]
      DatabaseCleaner.clean if defined?(::DB)
    end
  end
end
