#!/usr/bin/env ruby
begin

  $LOAD_PATH << "#{Dir.pwd}/lib"
  require "pact_broker/test/http_test_data_builder"
  base_url = ENV["PACT_BROKER_BASE_URL"] || "http://localhost:9292"

  td = PactBroker::Test::HttpTestDataBuilder.new(base_url)
  td.delete_pacticipant("tag-provider")
    .delete_pacticipant("tag-consumer")
    .publish_contract(consumer: "tag-consumer", provider: "tag-provider", consumer_version: "1", content_id: "1111", tag: "main")
    .publish_contract(consumer: "tag-consumer", provider: "tag-provider", consumer_version: "1", content_id: "1111", tag: "feat/x")
    .publish_contract(consumer: "tag-consumer", provider: "tag-provider", consumer_version: "2", content_id: "1111", tag: "feat/x")
    .get_pacts_for_verification(provider: "tag-provider", consumer_version_selectors: [{ tag: "main", latest: true }])
    .verify_pact(
      provider_version_tag: "main",
      provider_version: "1",
      success: true
    )
    .verify_pact(
      provider_version_tag: "feat/y",
      provider_version: "1",
      success: true
    )
    .verify_pact(
      provider_version_tag: "feat/y",
      provider_version: "2",
      success: true
    )

rescue StandardError => e
  puts "#{e.class} #{e.message}"
  puts e.backtrace
  exit 1
end
