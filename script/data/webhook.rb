#!/usr/bin/env ruby
begin

  $LOAD_PATH << "#{Dir.pwd}/lib"
  require "pact_broker/test/http_test_data_builder"
  base_url = ENV["PACT_BROKER_BASE_URL"] || "http://localhost:9292"

  td = PactBroker::Test::HttpTestDataBuilder.new(base_url)
  td.delete_webhook(uuid: "7a5da39c-8e50-4cc9-ae16-dfa5be043e8c")
    .create_global_webhook_for_contract_changed(uuid: "7a5da39c-8e50-4cc9-ae16-dfa5be043e8c")
    .delete_pacticipant("foo-consumer")
    .delete_pacticipant("bar-provider")
    .create_pacticipant("foo-consumer")
    .create_pacticipant("bar-provider")
    .publish_pact(consumer: "foo-consumer", consumer_version: "1", provider: "bar-provider", content_id: "111", tag: "main")


rescue StandardError => e
  puts "#{e.class} #{e.message}"
  puts e.backtrace
  exit 1
end
