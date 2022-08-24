#!/usr/bin/env ruby

# Demonstrates using can-i-deploy with a monorepo which contains two applications that have a bi-directional dependency, each of which will be deployed together.

begin

  $LOAD_PATH << "#{Dir.pwd}/lib"
  require "pact_broker/test/http_test_data_builder"
  base_url = ENV["PACT_BROKER_BASE_URL"] || "http://localhost:9292"


  # monorepo-app-1 <=> monorepo-app-2 (bi-directional dependency)
  # monorepo-app-1 => other-app

  # In production:
  # monorepo-app-1 v1
  # monorepo-app-2 v1
  # other-app v1

  # Trying to deploy monorepo-app-1 v2 and monorepo-app-2 v2 together
  # Both monorepo apps depend on each other and are NOT backwards compatible with the production versions of each other.

  app_1 = "monorepo-app-1"
  app_2 = "monorepo-app-2"
  other_app = "other-app"

  td = PactBroker::Test::HttpTestDataBuilder.new(base_url)
  td.delete_pacticipant(app_1)
    .delete_pacticipant(app_2)
    .publish_contract_and_verify(consumer: app_1, consumer_version: "1", content_id: "1111", provider: app_2, provider_version: "1")
    .publish_contract_and_verify(consumer: app_2, consumer_version: "1", content_id: "2323", provider: app_1, provider_version: "1")
    .publish_contract_and_verify(consumer: app_1, consumer_version: "1", content_id: "2222", provider: other_app, provider_version: "1")
    .record_deployment(pacticipant: app_1, version: "1", environment_name: "production")
    .record_deployment(pacticipant: app_2, version: "1", environment_name: "production")
    .record_deployment(pacticipant: other_app, version: "1", environment_name: "production")
    .publish_contract_and_verify(consumer: app_1, consumer_version: "2", content_id: "55", provider: app_2, provider_version: "2")
    .publish_contract_and_verify(consumer: app_2, consumer_version: "2", content_id: "66", provider: app_1, provider_version: "2")
    .publish_contract_and_verify(consumer: app_1, consumer_version: "2", content_id: "2222", provider: other_app, provider_version: "1")

rescue StandardError => e
  puts "#{e.class} #{e.message}"
  puts e.backtrace
  exit 1
end


# Scenario 1. Explicitly referencing each app in the mono-repo correctly allows the monorepo apps to be deployed, even though they are not backwards compatible with their
# production counterparts.
#
# pact-broker can-i-deploy --pacticipant monorepo-app-1 --version 2 --pacticipant monorepo-app-2 --version 2 --to-environment production
# Computer says yes \o/

# CONSUMER       | C.VERSION | PROVIDER       | P.VERSION | SUCCESS? | RESULT#
# ---------------|-----------|----------------|-----------|----------|--------
# monorepo-app-1 | 2         | monorepo-app-2 | 2         | true     | 1
# monorepo-app-1 | 2         | other-app      | 1         | true     | 2
# monorepo-app-2 | 2         | monorepo-app-1 | 2         | true     | 3

# VERIFICATION RESULTS
# --------------------
# 1. http://localhost:9292/pacts/provider/monorepo-app-2/consumer/monorepo-app-1/pact-version/634f96e8f39382863b4a303f90d3e7b2dc3c62f7/metadata/Y3ZuPTI/verification-results/123 (success)
# 2. http://localhost:9292/pacts/provider/other-app/consumer/monorepo-app-1/pact-version/5059297db8a62447489d2ce6d3148416440acd2e/metadata/Y3ZuPTI/verification-results/125 (success)
# 3. http://localhost:9292/pacts/provider/monorepo-app-1/consumer/monorepo-app-2/pact-version/dcbcba0dd09564f7dc031be90a4c9a8d316b0c5b/metadata/Y3ZuPTI/verification-results/124 (success)

# All required verification results are published and successful


# Scenario 2. Trying to deploy only one application from the monorepo shows us that can-i-deploy will not allow it.
#
# pact-broker can-i-deploy --pacticipant monorepo-app-1 --version 2 --to-environment production
# Computer says no ¯_(ツ)_/¯

# CONSUMER       | C.VERSION | PROVIDER       | P.VERSION | SUCCESS? | RESULT#
# ---------------|-----------|----------------|-----------|----------|--------
# monorepo-app-1 | 2         | monorepo-app-2 | ???       | ???      |
# monorepo-app-1 | 2         | other-app      | 1         | true     | 1
# monorepo-app-2 | 1         | monorepo-app-1 | ???       | ???      |

# VERIFICATION RESULTS
# --------------------
# 1. http://localhost:9292/pacts/provider/other-app/consumer/monorepo-app-1/pact-version/5059297db8a62447489d2ce6d3148416440acd2e/metadata/Y3ZuPTI/verification-results/125 (success)

# There is no verified pact between version 2 of monorepo-app-1 and the version of monorepo-app-2 currently deployed or released to production (1)
# There is no verified pact between the version of monorepo-app-2 currently deployed or released to production (1) and version 2 of monorepo-app-1
