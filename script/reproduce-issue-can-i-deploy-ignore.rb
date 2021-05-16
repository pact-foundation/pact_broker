#!/usr/bin/env ruby

# The content_id is used to deterministically generate pact content. It doesn't matter what the value is.
# If you want to simulate publishing a pact that has the same content as a previous pact, use the same ID.
# If you want to simulate publishing a pact with different content, use a different ID.

begin

  $LOAD_PATH << "#{Dir.pwd}/lib"
  require 'pact_broker/test/http_test_data_builder'
  base_url = ENV['PACT_BROKER_BASE_URL'] || 'http://localhost:9292'

  td = PactBroker::Test::HttpTestDataBuilder.new(base_url)
  td.delete_integration(consumer: "Foo", provider: "Bar")
    .delete_integration(consumer: "foo-consumer", provider: "bar-provider")
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
    .deploy_to_prod(pacticipant: "bar-provider", version: "1")
    .publish_pact(consumer: "foo-consumer", consumer_version: "1", provider: "baz-provider", content_id: "222", tag: "main") # missing
    .get_pacts_for_verification(
      enable_pending: true,
      provider_version_tag: "main",
      include_wip_pacts_since: "2020-01-01",
      consumer_version_selectors: [{ tag: "main", latest: true }])
    .verify_pact(
      index: 0,
      provider_version_tag: "main",
      provider_version: "4",
      success: false
    )
    .deploy_to_prod(pacticipant: "baz-provider", version: "4")
    .publish_pact(consumer: "foo-consumer", consumer_version: "1", provider: "dog-provider", content_id: "777", tag: "main") # missing

rescue StandardError => e
  puts "#{e.class} #{e.message}"
  puts e.backtrace
  exit 1
end
