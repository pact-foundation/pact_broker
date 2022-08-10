#!/usr/bin/env ruby
require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "faraday"
end

begin

  $LOAD_PATH << "#{Dir.pwd}/lib"
  require "pact_broker/test/http_test_data_builder"
  base_url = ENV["PACT_BROKER_BASE_URL"] || "http://localhost:9292"

  CONSUMER = "wip-consumer"
  PROVIDER = "wip-provider"

  td = PactBroker::Test::HttpTestDataBuilder.new(base_url)
  td.delete_pacticipant(CONSUMER)
    .delete_pacticipant(PROVIDER)
    .publish_pact_the_old_way(consumer: CONSUMER, consumer_version: "1", provider: PROVIDER, content_id: "111", branch: "main", tag: nil)
    .publish_pact_the_old_way(consumer: CONSUMER, consumer_version: "2", provider: PROVIDER, content_id: "222", branch: "feat/x", tag: nil)
    .get_pacts_for_verification(
      enable_pending: true,
      provider_version_branch: "main",
      provider_version_tag: nil,
      include_wip_pacts_since: "2020-01-01",
      consumer_version_selectors: [{ branch: "main" }]
    )


rescue StandardError => e
  puts "#{e.class} #{e.message}"
  puts e.backtrace
  exit 1
end
