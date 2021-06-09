#!/usr/bin/env ruby
begin

  $LOAD_PATH << "#{Dir.pwd}/lib"
  require "pact_broker/test/http_test_data_builder"
  base_url = "http://localhost:9292"

  webhook_body = {
    "canIMerge" => "${pactbroker.providerMainBranchGithubVerificationStatus}"
  }

  td = PactBroker::Test::HttpTestDataBuilder.new(base_url)
  td.delete_integration(consumer: "Foo", provider: "Bar")
    .delete_integration(consumer: "foo-consumer", provider: "bar-provider")
    .create_pacticipant("bar-provider", main_branch: "main")
    .create_global_webhook_for_anything_published(uuid: "58b7430d-dd0a-4239-ac66-1ff4d576f040")
    .publish_pact(consumer: "foo-consumer", consumer_version: "1", provider: "bar-provider", content_id: "111", tag: "main")
    .sleep(5)
    .get_pacts_for_verification(
      enable_pending: true,
      provider_version_branch: "main",
      include_wip_pacts_since: "2020-01-01",
      consumer_version_selectors: [{ tag: "main", latest: true }])
    .verify_pact(
      index: 0,
      provider_version_branch: "main",
      provider_version: "1",
      success: false
    )
    .sleep(5)
    .get_pacts_for_verification(
      enable_pending: true,
      provider_version_branch: "main",
      include_wip_pacts_since: "2020-01-01",
      consumer_version_selectors: [{ tag: "main", latest: true }])
    .verify_pact(
      index: 0,
      provider_version_branch: "main",
      provider_version: "2",
      success: true
    )

rescue StandardError => e
  puts "#{e.class} #{e.message}"
  puts e.backtrace
  exit 1
end
