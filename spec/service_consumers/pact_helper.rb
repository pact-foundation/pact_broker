require './spec/spec_helper'
require 'pact/provider/rspec'
require 'sequel'
require 'pact_broker/db'
require 'pact_broker/api'
require 'uri'
require_relative 'provider_states_for_pact_broker_client'

require 'pact_broker/api/resources/pact'

Pact.configure do | config |
  config.logger.level = Logger::DEBUG
end

Pact.service_provider "Pact Broker" do
#  app { PactBroker::API }

  honours_pact_with "Pact Broker Client" do
    pact_uri "../pact_broker-client/spec/pacts/pact_broker_client-pact_broker.json"
  end

  # honours_pact_with "Pact Broker Client", :ref => :head do
  #   pact_uri URI.encode("http://rea-pact-broker.biq.vpc.realestate.com.au/pact/provider/Pact Broker/consumer/Pact Broker Client/latest")
  # end

end
