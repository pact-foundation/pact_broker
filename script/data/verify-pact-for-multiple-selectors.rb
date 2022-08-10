#!/usr/bin/env ruby
begin

  $LOAD_PATH << "#{Dir.pwd}/lib"
  require "pact_broker/test/http_test_data_builder"
  base_url = ENV["PACT_BROKER_BASE_URL"] || "http://localhost:9292"

  td = PactBroker::Test::HttpTestDataBuilder.new(base_url)
  td.delete_pacticipant("some-consumer")
    .delete_pacticipant("some-provider")
    .create_pacticipant("some-consumer")
    .create_pacticipant("some-provider")
    .publish_pact_the_old_way(consumer: "some-consumer", consumer_version: "1", provider: "some-provider", content_id: "111", branch: "main")
    .publish_pact_the_old_way(consumer: "some-consumer", consumer_version: "2", provider: "some-provider", content_id: "111", branch: "feat/x")
    .get_pacts_for_verification(
      provider_version_tag: "main",
      consumer_version_selectors: [{ branch: "main" }, { branch: "feat/x" }]
    )
    .verify_pact(
      index: 0,
      provider_version_tag: "main",
      provider_version: "1",
      success: true
    )

rescue StandardError => e
  puts "#{e.class} #{e.message}"
  puts e.backtrace
  exit 1
end
