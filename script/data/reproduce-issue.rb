#!/usr/bin/env ruby

# The content_id is used to deterministically generate pact content. It doesn't matter what the value is.
# If you want to simulate publishing a pact that has the same content as a previous pact, use the same ID.
# If you want to simulate publishing a pact with different content, use a different ID.

#!/usr/bin/env ruby

# The content_id is used to deterministically generate pact content. It doesn't matter what the value is.
# If you want to simulate publishing a pact that has the same content as a previous pact, use the same ID.
# If you want to simulate publishing a pact with different content, use a different ID.

require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "faraday"
  gem "faraday_middleware"
end

begin

  $LOAD_PATH << "#{Dir.pwd}/lib"
  require "pact_broker/test/http_test_data_builder"
  base_url = ENV["PACT_BROKER_BASE_URL"] || "http://localhost:9292"

  td = PactBroker::Test::HttpTestDataBuilder.new(base_url)
  td.delete_pacticipant("foo-consumer-1")
    .delete_pacticipant("foo-consumer-2")
    .delete_pacticipant("bar-provider-1")
    .delete_pacticipant("bar-provider-2")
    .publish_pact(consumer: "foo-consumer-1", consumer_version: "1", provider: "bar-provider-1", content_id: "111", branch: "feat/x")
    .get_pacts_for_verification(
      enable_pending: true,
      provider_version_branch: "main",
      include_wip_pacts_since: "2020-01-01",
      consumer_version_selectors: [{ branch: "main" }]
    )
    .verify_pact(
      index: 0,
      provider_version_tag: "main",
      provider_version: "1",
      success: true
    )
    .publish_pact(consumer: "foo-consumer-2", consumer_version: "1", provider: "bar-provider-1", content_id: "112", branch: "feat/y")
    .get_pacts_for_verification(
      enable_pending: true,
      provider_version_branch: "main",
      include_wip_pacts_since: "2020-01-01",
      consumer_version_selectors: [{ branch: "main" }]
    )
    .verify_pact(
      index: 0,
      provider_version_tag: "main",
      provider_version: "1",
      success: true
    )
    .publish_pact(consumer: "foo-consumer-2", consumer_version: "2", provider: "bar-provider-2", content_id: "113", branch: "feat/z")
    .get_pacts_for_verification(
      enable_pending: true,
      provider_version_branch: "main",
      include_wip_pacts_since: "2020-01-01",
      consumer_version_selectors: [{ branch: "main" }]
    )
    .verify_pact(
      index: 0,
      provider_version_tag: "main",
      provider_version: "1",
      success: true
    )
    .deploy_to_prod(pacticipant: "foo-consumer-2", version: "2")
    .can_i_deploy(pacticipant: "bar-provider-1", version: "1", to: "prod")

rescue StandardError => e
  puts "#{e.class} #{e.message}"
  puts e.backtrace
  exit 1
end