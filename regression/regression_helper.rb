raise "Must set INSTALL_PG=true" unless ENV["INSTALL_PG"] == "true"
raise "Must set DATABASE_ADAPTER=docker_postgres" unless ENV["DATABASE_ADAPTER"] == "docker_postgres"
raise "Must set RACK_ENV=development" unless ENV["RACK_ENV"] == "development"

$LOAD_PATH  << "."

require 'sequel'

load 'lib/db.rb'
require 'tasks/database'
require 'pact_broker/db'
PactBroker::DB.connection = PactBroker::Database.database = DB::PACT_BROKER_DB
PactBroker::DB::Migrate.call(PactBroker::DB.connection)
require 'approvals'
require 'rack/test'
require 'pact_broker/api'

Approvals.configure do |c|
  c.approvals_path = 'regression/fixtures/approvals/'
end

RSpec.configure do | config |
  config.before :each do
    PactBroker.reset_configuration
    PactBroker.configuration.seed_example_data = false
    PactBroker.configuration.base_equality_only_on_content_that_affects_verification_results = false
  end

  config.include Rack::Test::Methods

  config.define_derived_metadata do |meta|
    meta[:aggregate_failures] = true unless meta.key?(:aggregate_failures)
  end

  config.example_status_persistence_file_path = "./regression/.examples.txt"
  config.filter_run_excluding skip: true

  def app
    PactBroker::API
  end
end

if ENV["DEBUG"] == "true"
  SemanticLogger.add_appender(io: $stdout)
  SemanticLogger.default_level = :info
end
