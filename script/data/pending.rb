#!/usr/bin/env ruby
begin

  $LOAD_PATH << "#{Dir.pwd}/lib"
  require "pact_broker/test/http_test_data_builder"
  base_url = ENV["PACT_BROKER_BASE_URL"] || "http://localhost:9292"

  td = PactBroker::Test::HttpTestDataBuilder.new(base_url)
  td.delete_pacticipant("some-demo-provider")
    .delete_pacticipant("some-demo-consumer")
    .publish_contract(consumer: "some-demo-consumer", provider: "some-demo-provider", consumer_version: "1", content_id: "1111", branch: "main")
    .publish_contract(consumer: "some-demo-consumer", provider: "some-demo-provider", consumer_version: "1", content_id: "1111", branch: "feat/x")
    .publish_contract(consumer: "some-demo-consumer", provider: "some-demo-provider", consumer_version: "2", content_id: "1111", branch: "feat/x")
    .get_pacts_for_verification(provider: "some-demo-provider")
    .verify_pact(
      provider_version_branch: "main",
      provider_version: "1",
      success: false
    )


rescue StandardError => e
  puts "#{e.class} #{e.message}"
  puts e.backtrace
  exit 1
end
