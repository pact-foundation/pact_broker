#!/usr/bin/env ruby

$LOAD_PATH << "#{Dir.pwd}/lib"

require 'pact_broker/test/http_test_data_builder'

td = PactBroker::Test::HttpTestDataBuilder.new('http://pact-broker:9292', { })
td.delete_integration(consumer: "Foo", provider: "Bar")
  .create_tagged_pacticipant_version(pacticipant: "Bar", version: "1", tag: "master")
  .sleep
  .publish_pact(consumer: "Foo", consumer_version: "1", provider: "Bar", content_id: "111", tag: "master")
  .sleep
  .publish_pact(consumer_version: "2", content_id: "222", tag: "feat-x")
  .sleep
  .get_pacts_for_verification(
    enable_pending: true,
    provider_version_tag: "master",
    include_wip_pacts_since: "2020-01-01",
    consumer_version_selectors: [{ tag: "master", latest: true }])
  .print_pacts_for_verification
