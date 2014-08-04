ENV['RACK_ENV'] = 'test'
RACK_ENV = 'test'

$: << File.expand_path("../../", __FILE__)
require 'rack/test'
require 'db'
require './spec/support/provider_state_builder'
require 'pact_broker/api'
require 'rspec/its'

YAML::ENGINE.yamler = 'psych'
I18n.config.enforce_available_locales = false

def load_fixture(file_name)
  File.read(File.expand_path(File.join(File.dirname(__FILE__), 'fixtures', file_name)))
end

def load_json_fixture(file_name)
  require 'json'
  JSON.parse(load_fixture(file_name))
end

RSpec.configure do | config |
  config.before :suite do
    raise "Wrong environment!!! Don't run this script!! ENV['RACK_ENV'] is #{ENV['RACK_ENV']} and RACK_ENV is #{RACK_ENV}" if ENV['RACK_ENV'] != 'test' || RACK_ENV != 'test'
  end

  config.before :each do
    # TODO: Change this to transactional!
    DB::PACT_BROKER_DB[:pacts].truncate
    DB::PACT_BROKER_DB[:tags].truncate
    DB::PACT_BROKER_DB[:versions].truncate
    DB::PACT_BROKER_DB[:pacticipants].truncate
    DB::PACT_BROKER_DB[:webhooks].truncate
    DB::PACT_BROKER_DB[:webhook_headers].truncate
  end

  config.include Rack::Test::Methods
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  def app
    PactBroker::API
  end
end
