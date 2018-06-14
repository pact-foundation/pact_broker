$: << File.expand_path("../../../", __FILE__)
require 'pact/provider/rspec'
require 'db'
require 'tasks/database'
require 'pact_broker/db'
PactBroker::DB.connection = PactBroker::Database.database = DB::PACT_BROKER_DB

require 'spec/support/database_cleaner'
require 'pact_broker'
require 'pact_broker/app'

require_relative 'hal_relation_proxy_app'

Dir.glob(File.join(File.dirname(__FILE__), "provider_states_for*.rb")).each do | path |
  require path
end

pact_broker = PactBroker::App.new { |c| c.database_connection = DB::PACT_BROKER_DB }
app_to_verify = HalRelationProxyApp.new(pact_broker)

module Rack
  module PactBroker
    class DatabaseTransaction
      def do_not_rollback? response
        # Dodgey hack to stop exceptions raising a Rollback error while verifying
        # Otherwise the provider states that deliberately raise exceptions
        # end up raising exceptions that break the verification tests
        true
      end
    end
  end
end

Pact.configuration.logger.level = Logger::DEBUG

Pact.service_provider "Pact Broker" do

  app { HalRelationProxyApp.new(app_to_verify) }

  honours_pact_with "Pact Broker Client" do
    pact_uri "https://raw.githubusercontent.com/pact-foundation/pact_broker-client/master/spec/pacts/pact_broker_client-pact_broker.json"
  end

end
