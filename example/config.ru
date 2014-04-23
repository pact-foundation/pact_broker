require 'fileutils'
require 'logger'
require 'sequel'
require 'pact_broker/db'
require 'pact_broker/logging'

FileUtils.mkdir_p "./log"

PactBroker.logger = Logger.new(File.join("./log/pact_broker.log"))
db_credentials = {database: "pact_broker_database.sqlite3", adapter: "sqlite"}
connection = Sequel.connect(db_credentials.merge(:logger => PactBroker.logger))

Sequel.extension :migration
Sequel::Migrator.run(connection, PactBroker::DB::MIGRATIONS_DIR)

# Require the Pact Broker API
require 'pact_broker/api'

# Mount it
run Rack::URLMap.new(
  '/' => PactBroker::API
)