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
end

begin

  $LOAD_PATH << "#{Dir.pwd}/lib"
  require "pact_broker/test/http_test_data_builder"
  base_url = ENV["PACT_BROKER_BASE_URL"] || "http://localhost:9292"

  CONSUMER = "FooService"
  PROVIDER = "BarService"

  puts "THIS IS THE SCENARIO WITH THE PROBLEM"
  puts ""
  puts ""

  td = PactBroker::Test::HttpTestDataBuilder.new(base_url)
  td.delete_pacticipant(CONSUMER)
    .delete_pacticipant(PROVIDER)
    .create_pacticipant(CONSUMER, main_branch: "main")
    .publish_contract(consumer: CONSUMER, consumer_version: "2", provider: PROVIDER, content_id: "111", branch: "feature/fun-123")
    .get_pacts_for_verification(
      provider: PROVIDER,
      enable_pending: true,
      provider_version_branch: "feature/fun-123",
      include_wip_pacts_since: "2020-01-01",
      consumer_version_selectors: [{ mainBranch: true }, { matchingBranch: true } , { deployedOrReleased: true }]
    )
    .verify_pact(
      index: 0,
      provider_version_branch: "feature/fun-123",
      provider_version: "2",
      success: true
    )
    .can_i_deploy(pacticipant: PROVIDER, version: "2", to_environment: "test")
    .get_pacts_for_verification(
      provider: PROVIDER,
      enable_pending: true,
      provider_version_branch: "main",
      include_wip_pacts_since: "2020-01-01",
      consumer_version_selectors: [{ mainBranch: true }, { matchingBranch: true } , { deployedOrReleased: true }]
    )

    puts ""
    puts ""
    puts ""
    puts ""
    puts "THIS IS AN ALTERNATIVE APPROACH THAT KEEPS THE PACT WIP ON MAIN"
    puts "The { matchingBranch: true } selector has been removed"
    puts ""
    puts ""

    td.delete_pacticipant(CONSUMER)
      .delete_pacticipant(PROVIDER)
      .create_pacticipant(CONSUMER, main_branch: "main")
      .publish_contract(consumer: CONSUMER, consumer_version: "2", provider: PROVIDER, content_id: "111", branch: "feature/fun-123")
      .get_pacts_for_verification(
        provider: PROVIDER,
        enable_pending: true,
        provider_version_branch: "feature/fun-123",
        include_wip_pacts_since: "2020-01-01",
        consumer_version_selectors: [{ mainBranch: true } , { deployedOrReleased: true }]
      )
      .verify_pact(
        index: 0,
        provider_version_branch: "feature/fun-123",
        provider_version: "2",
        success: true
      )
      .can_i_deploy(pacticipant: PROVIDER, version: "2", to_environment: "test")
      .get_pacts_for_verification(
        provider: PROVIDER,
        enable_pending: true,
        provider_version_branch: "main",
        include_wip_pacts_since: "2020-01-01",
        consumer_version_selectors: [{ mainBranch: true }, { deployedOrReleased: true }]
      )

rescue StandardError => e
  puts "#{e.class} #{e.message}"
  puts e.backtrace
  exit 1
end