#!/usr/bin/env ruby
begin

  $LOAD_PATH << "#{Dir.pwd}/lib"
  require "pact_broker/test/http_test_data_builder"
  base_url = ENV["PACT_BROKER_BASE_URL"] || "http://localhost:9292"

  td = PactBroker::Test::HttpTestDataBuilder.new(base_url)
  td.delete_integration(consumer: "Foo", provider: "Bar")
    .delete_integration(consumer: "foo-consumer", provider: "bar-provider")
    .create_environment(name: "test")
    .create_environment(name: "prod", production: true)
    .publish_pact(consumer: "foo-consumer", consumer_version: "1", provider: "bar-provider", content_id: "111", tag: "main")
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
    .record_deployment(pacticipant: "bar-provider", version: "1", environment_name: "test")
    .record_deployment(pacticipant: "bar-provider", version: "1", environment_name: "prod")
    .record_deployment(pacticipant: "foo-consumer", version: "1", environment_name: "prod")
    .get_pacts_for_verification(
      enable_pending: true,
      provider_version_tag: "main",
      include_wip_pacts_since: "2020-01-01",
      consumer_version_selectors: [{ tag: "main", latest: true }])
    .verify_pact(
      index: 0,
      provider_version_tag: "main",
      provider_version: "2",
      success: true
    )
    .record_deployment(pacticipant: "bar-provider", version: "2", environment_name: "test")
    .create_global_webhook_for_contract_changed(uuid: "7a5da39c-8e50-4cc9-ae16-dfa5be043e8c")
    .publish_pact(consumer: "foo-consumer", consumer_version: "2", provider: "bar-provider", content_id: "222", tag: "main")

rescue StandardError => e
  puts "#{e.class} #{e.message}"
  puts e.backtrace
  exit 1
end
