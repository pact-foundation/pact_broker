raise "Must set DATABASE_ADAPTER=docker_postgres" unless ENV["DATABASE_ADAPTER"] == "docker_postgres"
raise "Must set RACK_ENV=development" unless ENV["RACK_ENV"] == "development"

$LOAD_PATH  << "."

require "sequel"

require "support/test_database"
require "pact_broker/db"
PactBroker::DB.connection = PactBroker::TestDatabase.database = PactBroker::TestDatabase.connection_for_test_database
PactBroker::DB::Migrate.call(PactBroker::DB.connection)
require "approvals"
require "rack/test"
require "pact_broker/api"

Approvals.configure do |c|
  c.approvals_path = "regression/fixtures/approvals/"
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
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  def app
    PactBroker::API
  end

  config.after(:each) do | example, _something |
    if ENV["SHOW_REGRESSION_DIFF"] == "true"
      if example.exception.is_a?(Approvals::ApprovalError)
        require "pact/support"
        parts = example.exception.message.split('"')
        received_file = parts[1]
        approved_file = parts[3]
        received_hash = JSON.parse(File.read(received_file))
        approved_hash = JSON.parse(File.read(approved_file))
        diff = Pact::Matchers.diff(approved_hash, received_hash)
        puts Pact::Matchers::UnixDiffFormatter.call(diff)
      end
    end
  end
end

if ENV["DEBUG"] == "true"
  SemanticLogger.add_appender(io: $stdout)
  SemanticLogger.default_level = :info
end
