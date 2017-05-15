ENV['RACK_ENV'] = 'test'
RACK_ENV = 'test'

$: << File.expand_path("../../", __FILE__)
require 'rack/test'
require 'db'
require 'pact_broker/api'
require 'tasks/database'
require 'rspec/its'

Dir.glob("./spec/support/**/*.rb") { |file| require file  }

I18n.config.enforce_available_locales = false

RSpec.configure do | config |
  config.before :suite do
    raise "Wrong environment!!! Don't run this script!! ENV['RACK_ENV'] is #{ENV['RACK_ENV']} and RACK_ENV is #{RACK_ENV}" if ENV['RACK_ENV'] != 'test' || RACK_ENV != 'test'
    PactBroker::DB.connection = PactBroker::Database.database = DB::PACT_BROKER_DB
  end

  config.include Rack::Test::Methods
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.include FixtureHelpers

  def app
    PactBroker::API
  end
end
