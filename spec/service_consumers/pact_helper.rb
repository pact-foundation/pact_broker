require './spec/spec_helper'
require 'pact/provider/rspec'
require 'sequel'
require 'pact_broker/db'
require 'pact_broker/api'
require_relative 'provider_states_for_pact_broker_client'

Sequel.extension :migration


RSpec.configure do | config |
  config.before :suite do

    puts "RUNNING DB SETUP"
    raise "Wrong environment!!! Don't run this script!! ENV['RACK_ENV'] is #{ENV['RACK_ENV']} and RACK_ENV is #{RACK_ENV}" if ENV['RACK_ENV'] != 'test' || RACK_ENV != 'test'

    db_file = File.expand_path File.join(File.dirname(__FILE__), '../../tmp/pact_broker_database_test.sqlite3')
    puts "DB FILE IS #{db_file} #{RACK_ENV}"
    FileUtils.rm_rf db_file
    sleep 1
    Sequel::Migrator.run(DB::PACT_BROKER_DB, "db/migrations")
    sleep 1
  end

  config.before :each, :pact => :verify do
    sleep 1
    DB::PACT_BROKER_DB[:pacticipant].truncate
  end

end


Pact.service_provider "Pact Broker" do
  app { PactBroker::API.new }

  honours_pact_with "Pact Broker Client" do
    pact_uri "../pact_broker-client/spec/pacts/pact_broker_client-pact_broker.json"
  end

end
