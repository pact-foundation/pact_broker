require 'simplecov'
SimpleCov.start

ENV['RACK_ENV'] = 'test'
RACK_ENV = 'test'

$: << File.expand_path("../../", __FILE__)

require 'db'
require 'tasks/database'
require 'pact_broker/db'
raise "Wrong environment!!! Don't run this script!! ENV['RACK_ENV'] is #{ENV['RACK_ENV']} and RACK_ENV is #{RACK_ENV}" if ENV['RACK_ENV'] != 'test' || RACK_ENV != 'test'
PactBroker::DB.connection = PactBroker::Database.database = DB::PACT_BROKER_DB

require 'rack/test'
require 'pact_broker/api'
require 'rspec/its'
require 'rspec/pact/matchers'
require 'sucker_punch/testing/inline'
require 'webmock/rspec'

WebMock.disable_net_connect!(allow_localhost: true)

Dir.glob("./spec/support/**/*.rb") { |file| require file  }

I18n.config.enforce_available_locales = false

RSpec.configure do | config |
  config.before :each do
    PactBroker.reset_configuration
    PactBroker.configuration.base_equality_only_on_content_that_affects_verification_results = false
    require 'pact_broker/badges/service'
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
  config.example_status_persistence_file_path = "./spec/examples.txt"

  def app
    PactBroker::API
  end
end
