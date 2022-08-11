#!/usr/bin/env ruby
begin

  $LOAD_PATH << "#{Dir.pwd}/lib"
  require "pact_broker/test/http_test_data_builder"
  base_url = ENV["PACT_BROKER_BASE_URL"] || "http://localhost:9292"

  CONSUMER_NAME = "new-webhook-consumer"
  PROVIDER_NAME = "new-webhook-provider"

  td = PactBroker::Test::HttpTestDataBuilder.new(base_url)
  td.delete_webhook(uuid: "7a5da39c-8e50-4cc9-ae16-dfa5be043e8c")
    .delete_pacticipant(CONSUMER_NAME)
    .delete_pacticipant(PROVIDER_NAME)
    .create_pacticipant(CONSUMER_NAME)
    .create_pacticipant(PROVIDER_NAME)
    .create_global_webhook_for_contract_requiring_verification_published(uuid: "7a5da39c-8e50-4cc9-ae16-dfa5be043e8c")
    .publish_contract(consumer: CONSUMER_NAME, consumer_version: "1", provider: PROVIDER_NAME, content_id: "111", tag: "main")
    .get_pacts_for_verification(
      provider: PROVIDER_NAME,
      provider_version_branch: "main",
      consumer_version_selectors: [{ mainBranch: true }]
    )
    .verify_pact(
      index: 0,
      provider_version_branch: "main",
      provider_version: "1",
      success: true
    )
    .publish_contract(consumer: CONSUMER_NAME, consumer_version: "2", provider: PROVIDER_NAME, content_id: "222", tag: "main")


rescue StandardError => e
  puts "#{e.class} #{e.message}"
  puts e.backtrace
  exit 1
end

