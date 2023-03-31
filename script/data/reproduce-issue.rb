#!/usr/bin/env ruby

# The content_id is used to deterministically generate pact content. It doesn't matter what the value is.
# If you want to simulate publishing a pact that has the same content as a previous pact, use the same ID.
# If you want to simulate publishing a pact with different content, use a different ID.

require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "faraday"
end

begin

  $LOAD_PATH << "#{Dir.pwd}/lib"
  require "pact_broker/test/http_test_data_builder"
  base_url = ENV["PACT_BROKER_BASE_URL"] || "http://localhost:9292"

  CONSUMER = "foo"
  PROVIDER = "bar"

  td = PactBroker::Test::HttpTestDataBuilder.new(base_url)
  td.delete_pacticipant(CONSUMER)
    .delete_pacticipant(PROVIDER)
    .publish_contract(consumer: CONSUMER, consumer_version: "1", provider: PROVIDER, content_id: "111", branch: "main")
    .get_pacts_for_verification(
      provider: PROVIDER,
      enable_pending: true,
      provider_version_branch: "main",
      include_wip_pacts_since: "2020-01-01",
      consumer_version_selectors: [{ branch: "main" }]
    )
    .verify_pact(
      index: 0,
      provider: PROVIDER,
      provider_version_tag: "main",
      provider_version: "1",
      success: true
    )
    .can_i_deploy(pacticipant: PROVIDER, version: "1", to_environment: "production")
    .record_deployment(pacticipant: PROVIDER, version: "1", environment_name: "production")
    .can_i_deploy(pacticipant: CONSUMER, version: "1", to_environment: "production")
    .record_deployment(pacticipant: CONSUMER, version: "1", environment_name: "production")

rescue StandardError => e
  puts "#{e.class} #{e.message}"
  puts e.backtrace
  exit 1
end