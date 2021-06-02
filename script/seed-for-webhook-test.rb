#!/usr/bin/env ruby

raise "Please supply database path" unless ARGV[0]

$LOAD_PATH.unshift "./lib"
$LOAD_PATH.unshift "./spec"
$LOAD_PATH.unshift "./tasks"
ENV["RACK_ENV"] = "development"
require "sequel"
require "logger"
DATABASE_CREDENTIALS = {logger: Logger.new($stdout), adapter: "sqlite", database: ARGV[0], :encoding => "utf8"}.tap { |it| puts it }
#DATABASE_CREDENTIALS = {adapter: "postgres", database: "pact_broker", username: 'pact_broker', password: 'pact_broker', :encoding => 'utf8'}

connection = Sequel.connect(DATABASE_CREDENTIALS)
connection.timezone = :utc
# Uncomment these lines to open a pry session for inspecting the database

require "pact_broker/db"
PactBroker::DB.connection = connection
require "pact_broker"
require "support/test_data_builder"

require "database/table_dependency_calculator"
PactBroker::Database::TableDependencyCalculator.call(connection).each do | table_name |
  connection[table_name].delete
end

webhook_body = {
  "pactUrl" => "${pactbroker.pactUrl}",
  "verificationResultUrl" => "${pactbroker.verificationResultUrl}",
  "consumerVersionNumber" => "${pactbroker.consumerVersionNumber}",
  "providerVersionNumber" => "${pactbroker.providerVersionNumber}",
  "providerVersionTags" => "${pactbroker.providerVersionTags}",
  "consumerVersionTags" => "${pactbroker.consumerVersionTags}",
  "consumerName" => "${pactbroker.consumerName}",
  "providerName" => "${pactbroker.providerName}",
  "githubVerificationStatus" => "${pactbroker.githubVerificationStatus}"
}

  # .create_global_webhook(
  #   method: 'POST',
  #   url: "http://localhost:9292/pact-changed-webhook",
  #   body: webhook_body.to_json,
  #   username: "foo",
  #   password: "bar")

PactBroker.configuration.base_equality_only_on_content_that_affects_verification_results = false

TestDataBuilder.new
    .create_global_contract_published_webhook(
      method: "POST",
      url: "http://localhost:9292/pact-changed-webhook",
      body: webhook_body.to_json,
      username: "foo",
      password: "bar")
    .create_global_verification_webhook(
      method: "POST",
      url: "http://localhost:9292/verification-published-webhook",
      body: webhook_body.to_json)
