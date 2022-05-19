#!/usr/bin/env ruby
begin

  $LOAD_PATH << "#{Dir.pwd}/lib"
  require "pact_broker/test/http_test_data_builder"
  base_url = ENV["PACT_BROKER_BASE_URL"] || "http://localhost:9292"

  consumer_name = "daniel-issue-consumer"
  provider_name = "daniel-issue-provider"

  td = PactBroker::Test::HttpTestDataBuilder.new(base_url)
  td.create_global_webhook_for_contract_changed
    .delete_pacticipant(consumer_name)
    .delete_pacticipant(provider_name)
    .publish_contract(consumer: consumer_name, provider: provider_name, consumer_version: "1", content_id: "1111", tag: "test")

rescue StandardError => e
  puts "#{e.class} #{e.message}"
  puts e.backtrace
  exit 1
end
