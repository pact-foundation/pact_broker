$: << File.expand_path("../../../", __FILE__)

require "spec/support/simplecov"
require "pact/provider/rspec"
require "support/test_db"
require "support/test_database"
require "pact_broker/db"
require "pact_broker/configuration"
PactBroker::DB.connection = PactBroker::Database.database = ::TestDB.connection_for_test_database
PactBroker.configuration.seed_example_data = false
require "spec/support/database_cleaner"
require "pact_broker"
require "pact_broker/app"

require_relative "hal_relation_proxy_app"

Dir.glob(File.join(File.dirname(__FILE__), "provider_states_for*.rb")).each do | path |
  require path
end

PactBroker.configuration.base_urls = ["http://example.org"]

pact_broker = PactBroker::App.new { |c| c.database_connection = TestDB.connection_for_test_database }
app_to_verify = HalRelationProxyApp.new(pact_broker)

module Rack
  module PactBroker
    class DatabaseTransaction
      def do_not_rollback? _response
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
  app_version ENV["GIT_SHA"] if ENV["GIT_SHA"]
  app_version_tags [ENV["GIT_BRANCH"]] if ENV["GIT_BRANCH"]
  publish_verification_results ENV["CI"] == "true"

  if ENV.fetch("PACTFLOW_PACT_OSS_TOKEN", "") != ""
    honours_pacts_from_pact_broker do
      pact_broker_base_url "https://pact-oss.pactflow.io", token: ENV["PACTFLOW_PACT_OSS_TOKEN"]
      consumer_version_selectors [
          { tag: "master", latest: true }
        ]
      enable_pending true
      include_wip_pacts_since "2000-01-01"
    end
  end

  honours_pact_with "Pact Broker Client" do
    pact_uri "https://raw.githubusercontent.com/pact-foundation/pact_broker-client/master/spec/pacts/pact_broker_client-pact_broker.json"
  end
end
