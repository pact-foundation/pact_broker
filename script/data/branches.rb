#!/usr/bin/env ruby
begin

  $LOAD_PATH << "#{Dir.pwd}/lib"
  require "pact_broker/test/http_test_data_builder"
  base_url = ENV["PACT_BROKER_BASE_URL"] || "http://localhost:9292"

  td = PactBroker::Test::HttpTestDataBuilder.new(base_url)
  td.delete_pacticipant("branch-provider")
    .delete_pacticipant("branch-consumer")
    .publish_contract(consumer: "branch-consumer", provider: "branch-provider", consumer_version: "1", content_id: "1111", branch: "main")
    .publish_contract(consumer: "branch-consumer", provider: "branch-provider", consumer_version: "1", content_id: "1111", branch: "feat/x")
    .publish_contract(consumer: "branch-consumer", provider: "branch-provider", consumer_version: "2", content_id: "1111", branch: "feat/x")
    .get_pacts_for_verification(provider: "branch-provider", enable_pending: false, consumer_version_selectors: [ { branch: "main" }, { branch: "feat/x" }])
    .verify_pact(
      provider_version_branch: "main",
      provider_version: "1",
      success: true
    )
    .verify_pact(
      provider_version_branch: "feat/y",
      provider_version: "1",
      success: true
    )
    .verify_pact(
      provider_version_branch: "feat/y",
      provider_version: "2",
      success: false
    )

rescue StandardError => e
  puts "#{e.class} #{e.message}"
  puts e.backtrace
  exit 1
end
