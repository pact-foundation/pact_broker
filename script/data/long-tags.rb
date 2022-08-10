#!/usr/bin/env ruby
begin

  $LOAD_PATH << "#{Dir.pwd}/lib"
  require "pact_broker/test/http_test_data_builder"
  base_url = ENV["PACT_BROKER_BASE_URL"] || "http://localhost:9292"

  td = PactBroker::Test::HttpTestDataBuilder.new(base_url)
  td.delete_pacticipant("LongTagProvider")
    .create_environment(name: "prod", production: true)
    .create_pacticipant("LongTagProvider")
    .create_tagged_pacticipant_version(pacticipant: "LongTagProvider", version: "1", tag: "chore/update-from-oss-02b1c90b4113eb7fbe752a2991bf34f94898e845")
    .deploy_to_prod(pacticipant: "LongTagProvider", version: "1")
    .publish_pact_the_old_way(consumer: "LogTagConsumer", provider: "LongTagProvider", consumer_version: "1", tag: "chore/update-from-oss-05d35d2873b23a093478e92eb1193a77509873f7", content_id: "2111")
    .publish_pact_the_old_way(consumer: "LogTagConsumer", provider: "LongTagProvider", consumer_version: "2", tag: "chore/update-from-oss-0a7a25c68c62ff297b17a4cda3b6df5b6a7927fc", content_id: "21asdfd")
    .deploy_to_prod(pacticipant: "LogTagConsumer", version: "1")

rescue StandardError => e
  puts "#{e.class} #{e.message}"
  puts e.backtrace
  exit 1
end
