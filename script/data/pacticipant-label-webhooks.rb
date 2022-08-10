#!/usr/bin/env ruby
begin

  $LOAD_PATH << "#{Dir.pwd}/lib"
  require "pact_broker/test/http_test_data_builder"
  base_url = ENV["PACT_BROKER_BASE_URL"] || "http://localhost:9292"

  td = PactBroker::Test::HttpTestDataBuilder.new(base_url)
  td.delete_integration(consumer: "Foo", provider: "Bar")
    .delete_integration(consumer: "foo-consumer", provider: "bar-provider")
    .create_pacticipant("Foo")
    .create_pacticipant("Bar")
    .create_pacticipant("Baz")
    .create_label("Foo", "the_label")
    .create_label("Baz", "the_label")
    .create_webhook_for_event(
      uuid: "cf51d68a-78b1-4164-912a-986096b2c3b3",
      event_name: ["contract_published", "provider_verification_published"],
      consumer: {label: "the_label"}
    )
    .publish_pact_the_old_way(consumer: "Foo", consumer_version: "1", provider: "Bar", content_id: "111", tag: "main")
    .publish_pact_the_old_way(consumer: "Baz", consumer_version: "1", provider: "Bar", content_id: "122", tag: "main")
    .get_pacts_for_verification(
      enable_pending: true,
      provider_version_tag: "main",
      include_wip_pacts_since: "2020-01-01",
      consumer_version_selectors: [{ tag: "main", latest: true }])
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
