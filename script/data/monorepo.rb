#!/usr/bin/env ruby

# Demonstrates using can-i-deploy with a monorepo which contains two consumers, each of which will be deployed together.
# monorepo-app-1 -> provider 1
# monorepo-app-2 -> provider 2

begin

  $LOAD_PATH << "#{Dir.pwd}/lib"
  require "pact_broker/test/http_test_data_builder"
  base_url = ENV["PACT_BROKER_BASE_URL"] || "http://localhost:9292"


  consumer_1 = "monorepo-consumer-1"
  consumer_2 = "monorepo-consumer-2"
  provider_1 = "provider-1"
  provider_2 = "provider-2"


  td = PactBroker::Test::HttpTestDataBuilder.new(base_url)
  td.delete_pacticipant(consumer_1)
    .delete_pacticipant(consumer_2)
    .delete_pacticipant(provider_1)
    .delete_pacticipant(provider_2)
    .publish_contract(consumer: consumer_1, provider: provider_1, consumer_version: "1", content_id: "1111", branch: "main")
    .get_pacts_for_verification(provider: provider_1, consumer_version_selectors: [ { branch: "main" }])
    .verify_pact(
      provider_version_branch: "main",
      provider_version: "1",
      success: false
    )
    .record_deployment(pacticipant: provider_1, version: "1", environment_name: "production")
    .publish_contract(consumer: consumer_2, provider: provider_2, consumer_version: "1", content_id: "222", branch: "main")
    .get_pacts_for_verification(provider: provider_2, consumer_version_selectors: [ { branch: "main" }])
    .verify_pact(
      provider_version_branch: "main",
      provider_version: "1",
      success: true
    )
    .record_deployment(pacticipant: provider_2, version: "1", environment_name: "production")

rescue StandardError => e
  puts "#{e.class} #{e.message}"
  puts e.backtrace
  exit 1
end

# pact-broker can-i-deploy --pacticipant monorepo-consumer-1 --version 1 --pacticipant monorepo-consumer-2 --version 1 --to-environment production
# Computer says no ¯_(ツ)_/¯
#
# CONSUMER            | C.VERSION | PROVIDER   | P.VERSION | SUCCESS? | RESULT#
# --------------------|-----------|------------|-----------|----------|--------
# monorepo-consumer-1 | 1         | provider-1 | 1         | false    | 1
# monorepo-consumer-2 | 1         | provider-2 | 1         | true     | 2
#
# VERIFICATION RESULTS
# --------------------
# 1. http://localhost:9292/pacts/provider/provider-1/consumer/monorepo-consumer-1/pact-version/6e0b1c114e7b8a4775ff584af54bac734408e31a/metadata/Y3ZuPTE/verification-results/109 (failure)
# 2. http://localhost:9292/pacts/provider/provider-2/consumer/monorepo-consumer-2/pact-version/dd1edab05d6a9f4ff7dc4f17dbf3ea585c8220cb/metadata/Y3ZuPTE/verification-results/110 (success)
#
# The verification for the pact between version 1 of monorepo-consumer-1 and the version of provider-1 currently deployed or released to production (1) failed
