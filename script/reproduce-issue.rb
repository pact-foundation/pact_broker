#!/usr/bin/env ruby

begin

  $LOAD_PATH << "#{Dir.pwd}/lib"
  require 'pact_broker/test/http_test_data_builder'
  base_url = ENV['PACT_BROKER_BASE_URL'] || 'http://localhost:9292'

  td = PactBroker::Test::HttpTestDataBuilder.new(base_url)
  td.delete_integration(consumer: "foo-consumer", provider: "bar-provider")
    .create_pacticipant("foo-consumer")
    .create_pacticipant("foo-provider")
    .create_global_webhook_for_verification_published(uuid: "ba8feb17-558a-4b3f-a078-f52c6fafd014", url: "http://webhook-server:9393")
    .publish_pact(consumer: "foo-consumer", consumer_version: "1", provider: "bar-provider", content_id: "111", tag: "main")
    .publish_pact(consumer: "foo-consumer", consumer_version: "2", provider: "bar-provider", content_id: "111", tag: ["feat/x", "feat/y"])
    .sleep(10)
    .get_pacts_for_verification(
      provider_version_tag: "main",
      consumer_version_selectors: [{ tag: "main", latest: true }, { tag: "feat/x", latest: true }, { tag: "feat/y", latest: true }])
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
