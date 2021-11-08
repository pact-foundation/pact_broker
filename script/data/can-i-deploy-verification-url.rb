#!/usr/bin/env ruby
begin

  $LOAD_PATH << "#{Dir.pwd}/lib"
  require "pact_broker/test/http_test_data_builder"
  base_url = ENV["PACT_BROKER_BASE_URL"] || "http://localhost:9292"

  td = PactBroker::Test::HttpTestDataBuilder.new(base_url)
  td.delete_pacticipant("Foo")
    .delete_pacticipant("Bar")
    .create_environment(name: "test")
    .create_pacticipant("Foo")
    .create_pacticipant("Bar")
    .publish_pact(consumer: "Foo", consumer_version: "1", provider: "Bar", content_id: "111")
    .publish_pact(consumer: "Foo", consumer_version: "2", provider: "Bar", content_id: "111")
    .get_pacts_for_verification(provider_version_branch: "main")
    .verify_pact(provider_version_branch: "main", provider_version: "1")
    .record_deployment(pacticipant: "Bar", version: "1", environment_name: "test")
    .can_i_deploy(pacticipant: "Foo", version: "1", to_environment: "test")


rescue StandardError => e
  puts "#{e.class} #{e.message}"
  puts e.backtrace
  exit 1
end
