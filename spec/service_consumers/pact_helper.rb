require './spec/spec_helper'
require 'pact/provider/rspec'
require 'sequel'
require 'pact_broker/db'
require 'pact_broker/api'
require_relative 'provider_states_for_pact_broker_client'

Sequel.extension :migration


RSpec.configure do | config |
  config.before :suite do

    puts "BLAH"
    raise "Wrong environment!!! Don't run this script!! ENV['RACK_ENV'] is #{ENV['RACK_ENV']} and RACK_ENV is #{RACK_ENV}" if ENV['RACK_ENV'] != 'test' || RACK_ENV != 'test'
    begin
      db_file = File.expand_path File.join(File.dirname(__FILE__), '../../tmp/pact_broker_database_test.sqlite3')
      FileUtils.rm_rf db_file
      FileUtils.touch db_file
      Sequel::Migrator.run(DB::PACT_BROKER_DB, "./db/migrations")
    rescue StandardError => e
      puts e
    end
  end

  config.before :each do
    DB::PACT_BROKER_DB[:pacticipants].truncate
  end

end


Pact.service_provider "Pact Broker" do
  app { PactBroker::API.new }

  honours_pact_with "Pact Broker Client" do
    pact_uri "../pact_broker-client/spec/pacts/pact_broker_client-pact_broker.json"
  end

end
