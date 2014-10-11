ENV['RACK_ENV'] = 'test'
RACK_ENV = 'test'

$: << File.expand_path("../../", __FILE__)
require 'rack/test'
require 'db'
require 'pact_broker/api'
require 'rspec/its'

Dir.glob("./spec/support/**/*.rb") { |file| require file  }

YAML::ENGINE.yamler = 'psych'
I18n.config.enforce_available_locales = false

RSpec.configure do | config |
  config.before :suite do
    raise "Wrong environment!!! Don't run this script!! ENV['RACK_ENV'] is #{ENV['RACK_ENV']} and RACK_ENV is #{RACK_ENV}" if ENV['RACK_ENV'] != 'test' || RACK_ENV != 'test'
    PactBroker::DB.connection = DB::PACT_BROKER_DB
  end


  config.before :each do
    # TODO: Change this to transactional!
    DB::PACT_BROKER_DB[:webhook_headers].truncate
    DB::PACT_BROKER_DB[:webhooks].truncate
    DB::PACT_BROKER_DB[:pacts].truncate
    DB::PACT_BROKER_DB[:tags].truncate
    DB::PACT_BROKER_DB[:versions].truncate
    DB::PACT_BROKER_DB[:pacticipants].truncate
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
