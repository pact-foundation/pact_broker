# Can't stop the gression tests loading the spec_helper becaues of the .rspec file
# At least we can avoid executing it.
return if ENV["REGRESSION"] == "true"

$: << File.expand_path("../../", __FILE__)

RACK_ENV = ENV["RACK_ENV"] = "test"
ENV["PACT_BROKER_LOG_LEVEL"] ||= "fatal"
require "spec/support/simplecov"

require "support/logging"
require "support/database"
require "rack/test"
require "rspec/its"
require "rspec/pact/matchers"
require "sucker_punch/testing/inline"
require "webmock/rspec"
require "pact_broker/policies"

if ENV["OAS_COVERAGE_CHECK_ENABLED"] == "true"
  require "openapi_first"
  OpenapiFirst::Test.setup do |test|
    test.register("pact_broker_oas.yaml")
  end

  at_exit do
    oas_coverage = OpenapiFirst::Test::Coverage.result.coverage
    OpenapiFirst::Test.report_coverage
    if oas_coverage < 100
      puts "Exiting with status 2 (failure), because API coverage was #{oas_coverage}% instead of 100%!"
      exit 2
    end
  end
end

Dir.glob("./spec/support/**/*.rb") { |file| require file  }

WebMock.disable_net_connect!(allow_localhost: true)

I18n.config.enforce_available_locales = false


RSpec.configure do | config |
  config.before :each do
    PactBroker.reset_configuration
    PactBroker.configuration.seed_example_data = false
    PactBroker.configuration.base_equality_only_on_content_that_affects_verification_results = false
    require "pact_broker/badges/service"
    PactBroker::Badges::Service.clear_cache
  end

  config.after :suite do
    Pact::Fixture.check_fixtures
  end

  config.include Rack::Test::Methods
  config.include Pact::Fixture

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.define_derived_metadata do |meta|
    meta[:aggregate_failures] = true unless meta.key?(:aggregate_failures)
  end

  config.include FixtureHelpers
  config.include_context "test data builder"
  config.include_context "app"
  config.example_status_persistence_file_path = "./spec/examples.txt"
  config.filter_run_excluding skip: true
  config.include PactBroker::RackHelpers
end
