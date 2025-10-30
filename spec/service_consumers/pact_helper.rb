$: << File.expand_path("../../../", __FILE__)

require "spec/support/simplecov"
require "pact/provider/rspec"
require "support/test_database"
require "pact_broker/db"
require "pact_broker/configuration"
PactBroker::DB.connection = PactBroker::TestDatabase.database = ::PactBroker::TestDatabase.connection_for_test_database
PactBroker.configuration.seed_example_data = false
require "spec/support/database_cleaner"
require "pact_broker"
require "pact_broker/app"

require_relative "hal_relation_proxy_app"

Dir.glob(File.join(File.dirname(__FILE__), "provider_states_for*.rb")).each do | path |
  require path
end

PactBroker.configuration.base_urls = ["http://example.org"]

pact_broker = PactBroker::App.new { |c| c.database_connection = PactBroker::TestDatabase.connection_for_test_database }
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
  branch = `git rev-parse --abbrev-ref HEAD`.strip
  if branch.start_with?("refs/pull/") || branch.start_with?("HEAD")
    branch = ENV["GITHUB_HEAD_REF"] || branch.split("/").last
  end
  if branch.nil? || branch.empty?
    branch = ENV["GIT_BRANCH"]
  end
  app_version_branch branch
  publish_verification_results ENV["CI"] == "true"

  if ENV.fetch("PACT_BROKER_TOKEN", "") != ""
    honours_pacts_from_pact_broker do
      pact_broker_base_url ENV.fetch("PACT_BROKER_BASE_URL", ""), token: ENV["PACT_BROKER_TOKEN"]
      consumer_version_selectors [
          { mainBranch: true }, { deployed: true },
        ]
      enable_pending true
      include_wip_pacts_since "2000-01-01"
    end
  end

  honours_pact_with "Pact Broker Client" do
    pact_uri "https://raw.githubusercontent.com/pact-foundation/pact_broker-client/refs/heads/master/spec/pacts/Pact%20Broker%20Client%20V2-Pact%20Broker.json"
  end
end
