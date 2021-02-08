#!/usr/bin/env ruby
begin

  $LOAD_PATH << "#{Dir.pwd}/lib"
  require 'pact_broker/test/http_test_data_builder'
  base_url = ENV['PACT_BROKER_BASE_URL'] || 'http://localhost:9292'

  td = PactBroker::Test::HttpTestDataBuilder.new(base_url)
  td.delete_integration(consumer: "Foo", provider: "Bar")
    .delete_integration(consumer: "foo-consumer", provider: "bar-provider")
    .publish_pact(consumer: "foo-consumer", consumer_version: "1", provider: "bar-provider", content_id: "111", branch: "main")
    .publish_pact(consumer: "foo-consumer", consumer_version: "2", provider: "bar-provider", content_id: "222", tag: "feat/x")
    .get_pacts_for_verification(
      enable_pending: true,
      provider_version_branch: "main",
      provider_version_tag: "dev",
      include_wip_pacts_since: "2020-01-01",
      consumer_version_selectors: [{ branch: "main", latest: true }])
    .verify_pact(
      index: 0,
      provider_version: "1",
      success: true
    )
    .can_i_deploy(pacticipant: "bar-provider", version: "1", to: "prod")
    .deploy_to_prod(pacticipant: "bar-provider", version: "1")
    .can_i_deploy(pacticipant: "foo-consumer", version: "1", to: "prod")
    .deploy_to_prod(pacticipant: "foo-consumer", version: "1")

rescue StandardError => e
  puts "#{e.class} #{e.message}"
  puts e.backtrace
  exit 1
end
