#!/usr/bin/env ruby
begin

  $LOAD_PATH << "#{Dir.pwd}/lib"
  require "pact_broker/test/http_test_data_builder"
  base_url = ENV["PACT_BROKER_BASE_URL"] || "http://localhost:9292"

  CONSUMER_NAME = "c1"
  PROVIDER_NAME = "p1"
  PROVIDER_2_NAME = "p2"

  td = PactBroker::Test::HttpTestDataBuilder.new(base_url)
  td.delete_pacticipant(CONSUMER_NAME)
    .delete_pacticipant(PROVIDER_NAME)
    .publish_pact(consumer: CONSUMER_NAME, consumer_version: "1", provider: PROVIDER_NAME, content_id: "111", tag: "c1-p1-pact")
    .get_pacts_for_verification(
      provider: PROVIDER_NAME,
      consumer_version_selectors: [{ tag: "c1-p1-pact", latest: true }]
    )
    .verify_pact(
      index: 0,
      provider_version_tag: "main",
      provider_version: "1",
      success: true
    )
    .can_i_deploy(pacticipant: PROVIDER_NAME, version: "1", to: "env:test")
    .create_tag(pacticipant: PROVIDER_NAME, version: "1", tag: "env:test") # deploy p1
    .can_i_deploy(pacticipant: CONSUMER_NAME, version: "1", to: "env:test")
    .create_tag(pacticipant: CONSUMER_NAME, version: "1", tag: "env:test") # deploy c1
    .publish_pact(consumer: CONSUMER_NAME, consumer_version: "2", provider: PROVIDER_2_NAME, content_id: "222", tag: "c1-p2-pact")
    .get_pacts_for_verification(
      provider: PROVIDER_2_NAME,
      consumer_version_selectors: [{ tag: "c1-p2-pact", latest: true }]
    )
    .verify_pact(
      index: 0,
      provider_version_tag: "main",
      provider_version: "1",
      success: true
    )
    .can_i_deploy(pacticipant: PROVIDER_2_NAME, version: "1", to: "env:test")

rescue StandardError => e
  puts "#{e.class} #{e.message}"
  puts e.backtrace
  exit 1
end
