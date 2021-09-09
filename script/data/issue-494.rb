#!/usr/bin/env ruby
begin

  $LOAD_PATH << "#{Dir.pwd}/lib"
  require "pact_broker/test/http_test_data_builder"
  base_url = ENV["PACT_BROKER_BASE_URL"] || "http://localhost:9292"

  provider_name = "issue-494-provider"
  consumer_name = "issue-494-consumer"

  td = PactBroker::Test::HttpTestDataBuilder.new(base_url)
  td.delete_pacticipant(consumer_name)
    .delete_pacticipant(provider_name)
    .publish_contract(consumer: consumer_name, provider: provider_name, consumer_version: "1", content_id: "1111", tag: "test")
    .create_tag(pacticipant: consumer_name, version: "2", tag: "test")
    .get_pacts_for_verification(
      provider: provider_name,
      consumer_version_selectors: [{ tag: "test", latest: true }]
    )

rescue StandardError => e
  puts "#{e.class} #{e.message}"
  puts e.backtrace
  exit 1
end
