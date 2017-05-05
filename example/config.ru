require 'fileutils'
require 'logger'
require 'sequel'
# require 'pg' # for postgres
require 'pact_broker'

# Create a real database, and set the credentials for it here
# It is highly recommended to set the encoding to utf8 (varchar foreign keys may blow up otherwise)
DATABASE_CREDENTIALS = {adapter: "sqlite", database: "pact_broker_database.sqlite3", :encoding => 'utf8'}

# For postgres:
#
# $ psql postgres
# > create database pact_broker;
# > CREATE USER pact_broker WITH PASSWORD 'pact_broker';
# > GRANT ALL PRIVILEGES ON DATABASE pact_broker to pact_broker;
#
# DATABASE_CREDENTIALS = {adapter: "postgres", database: "pact_broker", username: 'pact_broker', password: 'pact_broker', :encoding => 'utf8'}

# Have a look at the Sequel documentation to make decisions about things like connection pooling
# and connection validation.

app = PactBroker::App.new do | config |
  # change these from their default values if desired
  # config.log_dir = "./log"
  # config.auto_migrate_db = true
  # config.use_hal_browser = true
  config.database_connection = Sequel.connect(DATABASE_CREDENTIALS.merge(:logger => config.logger))
  config.database_connection.timezone = :utc
  # See configuration section of wiki for more basic auth configuration options
  # config.protect_with_basic_auth :app_read, {username: 'username', password: 'password'}
end

run app
