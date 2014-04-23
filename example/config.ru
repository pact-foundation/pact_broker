require 'fileutils'
require 'logger'
require 'sequel'
require 'pact_broker'
require 'rack/hal_browser'

# Create a real database, and set the credentials for it here
DATABASE_CREDENTIALS = {database: "pact_broker_database.sqlite3", adapter: "sqlite"}
LOG_DIR = "./log"

# Configure application and setup database
FileUtils.mkdir_p LOG_DIR
PactBroker.logger = Logger.new(File.join(LOG_DIR, "pact_broker.log"))
PactBroker::DB.connection = Sequel.connect(DATABASE_CREDENTIALS.merge(:logger => PactBroker.logger))
PactBroker::DB.run_migrations

# Require API after the DB connection has been made so Sequel Model can work
require 'pact_broker/api'

# Set up HAL browser
use Rack::HalBrowser::Redirect, :exclude => ['/trace']

# Mount API
run Rack::URLMap.new(
  '/' => PactBroker::API
)
