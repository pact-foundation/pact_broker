require 'fileutils'
require 'logger'
require 'sequel'
require 'pact_broker'

# Create a real database, and set the credentials for it here
DATABASE_CREDENTIALS = {database: "pact_broker_database.sqlite3", adapter: "sqlite", :encoding => 'utf8'}

# Have a look at the Sequel documentation to make decisions about things like connection pooling
# and connection validation.

app = PactBroker::App.new do | config |
  # change these from their default values if desired
  # config.log_dir = "./log"
  # config.auto_migrate_db = true
  # config.use_hal_browser = true
  config.database_connection = Sequel.connect(DATABASE_CREDENTIALS.merge(:logger => config.logger))
end

run app