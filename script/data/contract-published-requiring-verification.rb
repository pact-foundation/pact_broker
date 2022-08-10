#!/usr/bin/env ruby
begin

  $LOAD_PATH << "#{Dir.pwd}/lib"
  require "pact_broker/test/http_test_data_builder"
  base_url = ENV["PACT_BROKER_BASE_URL"] || "http://localhost:9292"

  td = PactBroker::Test::HttpTestDataBuilder.new(base_url)
  td.create_global_webhook_for_event(uuid: "7a5da39c-8e50-4cc9-ae16-dfa5be043e8c", event_name: "contract_requiring_verification_published")
    .delete_pacticipant("NewWebhookTestConsumer")
    .delete_pacticipant("NewWebhookTestProvider")
    .create_environment(name: "test")
    .create_environment(name: "prod", production: true)
    .create_pacticipant("NewWebhookTestConsumer")
    .create_pacticipant("NewWebhookTestProvider")
    .create_tagged_pacticipant_version(pacticipant: "NewWebhookTestProvider", version: "1", tag: "main")
    .record_deployment(pacticipant: "NewWebhookTestProvider", version: "1", environment_name: "test")
    .record_deployment(pacticipant: "NewWebhookTestProvider", version: "1", environment_name: "prod")
    .create_version(pacticipant: "NewWebhookTestProvider", version: "2", branch: "main")
    .publish_pact_the_old_way(consumer: "NewWebhookTestConsumer", consumer_version: "1", provider: "NewWebhookTestProvider", content_id: "111")

rescue StandardError => e
  puts "#{e.class} #{e.message}"
  puts e.backtrace
  exit 1
end
