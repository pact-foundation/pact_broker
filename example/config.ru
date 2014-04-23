require 'fileutils'
require 'logger'
require 'sequel'
require 'pact_broker'
require 'rack/hal_browser'

FileUtils.mkdir_p "./log"
PactBroker.logger = Logger.new(File.join("./log/pact_broker.log"))

# Create a real database, and set the credentials for it here
db_credentials = {database: "pact_broker_database.sqlite3", adapter: "sqlite"}
connection = Sequel.connect(db_credentials.merge(:logger => PactBroker.logger))

Sequel.extension :migration
Sequel::Migrator.run(connection, PactBroker::DB::MIGRATIONS_DIR)

# Require the Pact Broker API, must be done AFTER the DB connection has been made
require 'pact_broker/api'

use Rack::HalBrowser::Redirect, :exclude => ['/trace']

run Rack::URLMap.new(
  '/' => PactBroker::API
)
