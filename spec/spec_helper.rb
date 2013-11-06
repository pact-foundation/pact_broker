require 'simplecov' # At the top because simplecov needs to watch files being loaded
ENV['RACK_ENV'] = 'test'
RACK_ENV = 'test'

$: << File.expand_path("../../", __FILE__)

require 'pact_broker/db'

RSpec.configure do | config |
  config.before :suite do
    raise "Wrong environment!!! Don't run this script!! ENV['RACK_ENV'] is #{ENV['RACK_ENV']} and RACK_ENV is #{RACK_ENV}" if ENV['RACK_ENV'] != 'test' || RACK_ENV != 'test'
    # puts caller.take 20
  end

  config.before :each do
    DB::PACT_BROKER_DB[:pacts].truncate
    DB::PACT_BROKER_DB[:tags].truncate
    DB::PACT_BROKER_DB[:versions].truncate
    DB::PACT_BROKER_DB[:pacticipants].truncate
  end

end
