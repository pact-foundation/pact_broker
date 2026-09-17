#!/usr/bin/env ruby

# Boots the broker the way the Docker image does, with only runtime gems
# installed, then exercises the request paths that load code lazily. Run
# with BUNDLE_WITHOUT=development:test so a require that is only satisfied
# by a test-group gem fails here rather than in the image.

require "base64"
require "fileutils"
require "json"
require "rack"
require "pact_broker"

DB_PATH = "tmp/runtime_boot_check.sqlite3"
CONSUMER = "Example App"
PROVIDER = "Example API"
# A consumer version seeded by PactBroker::DB::SeedExampleData that has a
# distinct previous pact.
SEEDED_VERSION = "7bd4d9173522826dc3e8704fd62dde0424f4c827"

FileUtils.mkdir_p("tmp")
FileUtils.rm_f(DB_PATH)

app = PactBroker::App.new do |config|
  config.log_stream = :stdout
  config.database_url = "sqlite://#{DB_PATH}"
  config.seed_example_data = true
end

request = Rack::MockRequest.new(app)
pact_base = "/pacts/provider/#{Rack::Utils.escape_path(PROVIDER)}/consumer/#{Rack::Utils.escape_path(CONSUMER)}"

def check(description, response, expected_status)
  if response.status == expected_status
    puts "ok   #{description} (#{response.status})"
  else
    puts "FAIL #{description}: expected #{expected_status}, got #{response.status}"
    puts response.body[0, 4000]
    exit 1
  end
end

check("HTML pact page", request.get("#{pact_base}/latest", "HTTP_ACCEPT" => "text/html"), 200)

check("pact diff", request.get("#{pact_base}/version/#{SEEDED_VERSION}/diff/previous-distinct"), 200)

conflicting_contract = { consumer: { name: CONSUMER }, provider: { name: PROVIDER }, interactions: [] }.to_json
publish_body = {
  pacticipantName: CONSUMER,
  pacticipantVersionNumber: SEEDED_VERSION,
  contracts: [
    {
      consumerName: CONSUMER,
      providerName: PROVIDER,
      specification: "pact",
      contentType: "application/json",
      content: Base64.strict_encode64(conflicting_contract)
    }
  ]
}.to_json
check(
  "conflicting publish renders a diff notice",
  request.post("/contracts/publish", input: publish_body, "CONTENT_TYPE" => "application/json", "HTTP_ACCEPT" => "application/hal+json"),
  409
)
