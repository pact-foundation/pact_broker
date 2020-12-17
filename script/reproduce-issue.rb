#!/usr/bin/env ruby

$LOAD_PATH << "#{Dir.pwd}/lib"

begin

  require 'pact_broker/test/http_test_data_builder'
  base_url = ENV['PACT_BROKER_BASE_URL'] || 'http://localhost:9292'

  td = PactBroker::Test::HttpTestDataBuilder.new(base_url, { })
  td.delete_integration(consumer: "MyConsumer", provider: "MyProvider")
    .create_pacticipant("MyConsumer")
    .create_pacticipant("MyProvider")
    .publish_pact(consumer: "MyConsumer", consumer_version: "1", provider: "MyProvider", content_id: "111", tag: "main")
    .publish_pact(consumer: "MyConsumer", consumer_version: "2", provider: "MyProvider", content_id: "222", tag: "main")
    .publish_pact(consumer: "MyConsumer", consumer_version: "3", provider: "MyProvider", content_id: "111", tag: "feat/a")
    .get_pacts_for_verification(
      provider_version_tag: "main",
      consumer_version_selectors: [{ tag: "main" }, { tag: "feat/a", latest: true }])
    .verify_pact(success: true, provider_version_tag: "main", provider_version: "2" )


rescue StandardError => e
  puts "#{e.class} #{e.message}"
  puts e.backtrace
  exit 1
end

