#!/usr/bin/env ruby

require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "faraday"
end

begin

  $LOAD_PATH << "#{Dir.pwd}/lib"
  require "pact_broker/test/http_test_data_builder"
  base_url = ENV["PACT_BROKER_BASE_URL"] || "http://localhost:9292"

  td = PactBroker::Test::HttpTestDataBuilder.new(base_url)
  td.delete_pacticipant("some-consumer")
    .delete_pacticipant("some-provider")
    .create_pacticipant("some-consumer")
    .create_pacticipant("some-provider")
    .publish_pact(consumer: "some-consumer", consumer_version: "1", provider: "some-provider", content_id: "111", branch: "main")
    .get_pacts_for_verification(
      provider_version_branch: "main",
      consumer_version_selectors: [{ branch: "main" }]
    )
    .verify_pact(
      index: 0,
      provider_version_branch: "main",
      provider_version: "1",
      success: true
    )
    # deploy provider
    .can_i_deploy(pacticipant: "some-provider", version: "1", to_environment: "test")
    .record_deployment(pacticipant: "some-provider", version: "1", environment_name: "test")
    # deploy consumer
    .can_i_deploy(pacticipant: "some-consumer", version: "1", to_environment: "test")
    .record_deployment(pacticipant: "some-consumer", version: "1", environment_name: "test")
    # create a consumer version with no pact
    .create_version(pacticipant: "some-consumer", version: "2", branch: "main")
    # There are no pacts for verification now
    .get_pacts_for_verification(
      provider_version_branch: "main",
      consumer_version_selectors: [{ branch: "main" }]
    )
    # create a provider version with no verifications
    .create_version(pacticipant: "some-provider", version: "2", branch: "main")
    # Can't deploy provider yet because the deployed consumer still needs the previous version
    .can_i_deploy(pacticipant: "some-provider", version: "2", to_environment: "test")
    # deploy consumer version that doesn't need the provider
    .can_i_deploy(pacticipant: "some-consumer", version: "2", to_environment: "test")
    .record_deployment(pacticipant: "some-consumer", version: "2", environment_name: "test")
    # deploy the provider
    .can_i_deploy(pacticipant: "some-provider", version: "2", to_environment: "test")
    .record_deployment(pacticipant: "some-provider", version: "2", environment_name: "test")


rescue StandardError => e
  puts "#{e.class} #{e.message}"
  puts e.backtrace
  exit 1
end
