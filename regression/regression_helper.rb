ENV['DATABASE_ADAPTER'] = 'docker_postgres'
ENV['RACK_ENV'] = 'development'

require 'db'
require 'tasks/database'
require 'pact_broker/db'
PactBroker::DB.connection = PactBroker::Database.database = DB::PACT_BROKER_DB

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
