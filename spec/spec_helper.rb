ENV['RACK_ENV'] = 'test'
RACK_ENV = 'test'

$: << File.expand_path("../../", __FILE__)

require 'rack/test'
require 'db'
require './spec/support/provider_state_builder'
require 'pact_broker/api'
require 'rspec/fire'

RSpec.configure do | config |
  config.before :suite do
    raise "Wrong environment!!! Don't run this script!! ENV['RACK_ENV'] is #{ENV['RACK_ENV']} and RACK_ENV is #{RACK_ENV}" if ENV['RACK_ENV'] != 'test' || RACK_ENV != 'test'
  end

  config.before :each do
    DB::PACT_BROKER_DB[:pacts].truncate
    DB::PACT_BROKER_DB[:tags].truncate
    DB::PACT_BROKER_DB[:versions].truncate
    DB::PACT_BROKER_DB[:pacticipants].truncate
  end

  config.include Rack::Test::Methods
  config.include RSpec::Fire

  def app
    PactBroker::API
  end
end
