#!/usr/bin/env ruby
begin

  $LOAD_PATH << "#{Dir.pwd}/lib"
  require "pact_broker/test/http_test_data_builder"
  base_url = ENV["PACT_BROKER_BASE_URL"] || "http://localhost:9292"

  td = PactBroker::Test::HttpTestDataBuilder.new(base_url)
  td.delete_integration(consumer: "Foo", provider: "Bar")
    .delete_integration(consumer: "foo-consumer", provider: "bar-provider")
    .create_global_webhook_for_event(uuid: "7a5da39c-8e50-4cc9-ae16-dfa5be043e8c", event_name: "contract_requiring_verification_published")
    .create_environment(name: "test")
    .create_environment(name: "prod", production: true)
    .create_pacticipant("Foo", main_branch: "main")
    .create_pacticipant("Bar", main_branch: "main")
    .create_version(pacticipant: "Bar", version: "1", branch: "main")
    .record_deployment(pacticipant: "Bar", version: "1", environment_name: "test")
    .record_deployment(pacticipant: "Bar", version: "1", environment_name: "prod")
    .create_version(pacticipant: "Bar", version: "2", branch: "main")
    .publish_pact(consumer: "Foo", consumer_version: "1", provider: "Bar", content_id: "111")

rescue StandardError => e
  puts "#{e.class} #{e.message}"
  puts e.backtrace
  exit 1
end
