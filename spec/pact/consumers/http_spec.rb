# frozen_string_literal: true
 
require "pact_broker"
require "pact_broker/app"
require "rspec/mocks"
include RSpec::Mocks::ExampleMethods
require_relative "../../service_consumers/hal_relation_proxy_app"

PactBroker.configuration.base_urls = ["http://example.org"]

pact_broker = PactBroker::App.new { |c| c.database_connection = PactBroker::TestDatabase.connection_for_test_database }
app_to_verify = HalRelationProxyApp.new(pact_broker)

require "pact"
require "pact/rspec"
require_relative "../../service_consumers/shared_provider_states"


RSpec.describe "Verify consumers for Pact Broker", :pact do

  http_pact_provider "Pact Broker", opts: { 

    app: app_to_verify,

    http_port: 9393, 
      
    log_level: :info,
    
    fail_if_no_pacts_found: true,
   
    enable_pending: true,
    # include_wip_pacts_since: "2021-01-01",

    publish_verification_results: ENV["PACT_PUBLISH_VERIFICATION_RESULTS"] == "true",
    provider_version: `git rev-parse HEAD`.strip,
    provider_version_branch: `git rev-parse --abbrev-ref HEAD`.strip,
    provider_version_tags: [`git rev-parse --abbrev-ref HEAD`.strip],
    
  }

  before_state_setup do
    PactBroker::TestDatabase.truncate
  end

  after_state_teardown do
    PactBroker::TestDatabase.truncate
  end

  shared_provider_states
  
end


