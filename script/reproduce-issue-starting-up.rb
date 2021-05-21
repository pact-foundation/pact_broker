#!/usr/bin/env ruby

# To show issue on master, need to set RACK_ENV=production to turn off feature toggle

begin
  $LOAD_PATH << "#{Dir.pwd}/lib"
  require 'pact_broker/test/http_test_data_builder'
  base_url = ENV['PACT_BROKER_BASE_URL'] || 'http://localhost:9292'

  td = PactBroker::Test::HttpTestDataBuilder.new(base_url)
  td.delete_integration(consumer: "Foo", provider: "Bar")
    .delete_integration(consumer: "foo-consumer", provider: "bar-provider")
    .create_pacticipant("foo-consumer")
    .create_pacticipant("foo-provider")
    .create_version(pacticipant: "foo-provider", version: "0", branch: nil)
    .publish_pact(consumer: "foo-consumer", consumer_version: "1", provider: "bar-provider", content_id: "111", tag: "main")
    .publish_pact(consumer: "foo-consumer", consumer_version: "2", provider: "bar-provider", content_id: "222", tag: ["feat/x", "feat/y"])
    .sleep(1)
    .get_pacts_for_verification(
      provider_version_tag: "main",
      consumer_version_selectors: [{ tag: "main", latest: true }],
      include_wip_pacts_since: "2020-01-01",
      enable_pending: true
    )
    .comment("There should have been 2 pacts to verify here")
    .verify_pact(
      index: 0,
      provider_version_tag: "main",
      provider_version: "1",
      success: true
    )


rescue StandardError => e
  puts "#{e.class} #{e.message}"
  puts e.backtrace
  exit 1
end
