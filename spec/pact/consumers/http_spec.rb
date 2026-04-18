# frozen_string_literal: true
require "pact_broker"
require "rspec/mocks"
include RSpec::Mocks::ExampleMethods
require_relative "../../service_consumers/hal_relation_proxy_app"

PactBroker::Configuration.configuration.base_urls = ["http://example.org"]

pact_broker = PactBroker::App.new { |c| c.database_connection = PactBroker::TestDatabase.connection_for_test_database }
app_to_verify = HalRelationProxyApp.new(pact_broker)

require "pact"
require "pact/v2/rspec"
require_relative "../../service_consumers/shared_provider_states"
RSpec.describe "Verify consumers for Pact Broker", :pact_v2 do

  http_pact_provider "Pact Broker", opts: { 

    # rails apps should be automatically detected
    # if you need to configure your own app, you can do so here

    app: app_to_verify,
    # start rackup with a different port. Useful if you already have something
    # running on the default port *9292*
    http_port: 9393, 
    
    # Set the log level, default is :info
  
    log_level: :info,
    logger: Logger.new(File.expand_path("../../../pact_verification.log", __dir__)),
    
    fail_if_no_pacts_found: true,

    # Pact Sources

    # 1. Local pacts from a directory

    # Default is pacts directory in the current working directory
    # pact_dir: File.expand_path('../../../../consumer/spec/internal/pacts', __dir__),
    
    # 2. Broker based pacts

    # Broker credentials
  
    # broker_username: "pact_workshop", # can be set via PACT_BROKER_USERNAME env var
    # broker_password: "pact_workshop", # can be set via PACT_BROKER_PASSWORD env var
    # broker_token: "pact_workshop", # can be set via PACT_BROKER_TOKEN env var
  
    # Remote pact via a uri, traditionally triggered via webhooks
    # when a pact that requires verification is published
  
    # 2a. Webhook triggered pacts
    # Can be a local file or a remote URL
    # Most used via webhooks
    # Can be set via PACT_URL env var
    # pact_uri: File.expand_path("../../../pacts/pact.json", __dir__),
    pact_uri: "https://raw.githubusercontent.com/pact-foundation/pact_broker-client/refs/heads/master/spec/pacts/Pact%20Broker%20Client%20V2-Pact%20Broker.json",
    
    # 2b. Dynamically fetched pacts from broker

    # i. Set the broker url
    # broker_url: "http://localhost:9292", # can be set via PACT_BROKER_URL env var

    # ii. Set the consumer version selectors 
    # Consumer version selectors
    # The pact broker will return the following pacts by default, if no selectors are specified
    # For the recommended setup, you dont _actually_ need to specify these selectors in ruby
    # consumer_version_selectors: [{"deployedOrReleased" => true},{"mainBranch" => true},{"matchingBranch" => true}],
 
    # iii. Set additional dynamic selection verification options
    # additional dynamic selection verification options
    enable_pending: true,
    include_wip_pacts_since: "2021-01-01",

    # Publish verification results to the broker
    publish_verification_results: ENV["PACT_PUBLISH_VERIFICATION_RESULTS"] == "true",
    provider_version: `git rev-parse HEAD`.strip,
    provider_version_branch: `git rev-parse --abbrev-ref HEAD`.strip,
    provider_version_tags: [`git rev-parse --abbrev-ref HEAD`.strip],
    # provider_build_uri: "YOUR CI URL HERE - must be a valid url",
    
  }

  before_state_setup do
    PactBroker::TestDatabase.truncate
  end

  after_state_teardown do
    PactBroker::TestDatabase.truncate
  end

  shared_provider_states
  
end


