#!/usr/bin/env ruby

raise "Please supply database path" unless ARGV[0]

$LOAD_PATH.unshift "./lib"
$LOAD_PATH.unshift "./spec"
$LOAD_PATH.unshift "./tasks"
ENV["RACK_ENV"] = "development"
require "sequel"
require "logger"
require "stringio"
# logger = Logger.new($stdout)
logger = Logger.new(StringIO.new)
DATABASE_CREDENTIALS = {logger: logger, adapter: "sqlite", database: ARGV[0], :encoding => "utf8"}.tap { |it| puts it }
#DATABASE_CREDENTIALS = {adapter: "postgres", database: "pact_broker", username: 'pact_broker', password: 'pact_broker', :encoding => 'utf8'}

connection = Sequel.connect(DATABASE_CREDENTIALS)
connection.timezone = :utc
# Uncomment these lines to open a pry session for inspecting the database

# require 'pry'; pry(binding);
# exit

require "pact_broker/db"
PactBroker::DB.connection = connection
require "pact_broker"
require "support/test_data_builder"

require "database/table_dependency_calculator"
PactBroker::Database::TableDependencyCalculator.call(connection).each do | table_name |
  connection[table_name].delete
end

# .create_webhook(method: 'GET', url: 'https://localhost:9393?url=${pactbroker.pactUrl}', body: '${pactbroker.pactUrl}')

# webhook_body = {
#   'pactUrl' => '${pactbroker.pactUrl}',
#   'verificationResultUrl' => '${pactbroker.verificationResultUrl}',
#   'consumerVersionNumber' => '${pactbroker.consumerVersionNumber}',
#   'providerVersionNumber' => '${pactbroker.providerVersionNumber}',
#   'providerVersionTags' => '${pactbroker.providerVersionTags}',
#   'consumerVersionTags' => '${pactbroker.consumerVersionTags}',
#   'consumerName' => '${pactbroker.consumerName}',
#   'providerName' => '${pactbroker.providerName}',
#   'githubVerificationStatus' => '${pactbroker.githubVerificationStatus}'
# }

PactBroker.configuration.base_equality_only_on_content_that_affects_verification_results = false

# json_content = <<-HEREDOC
# {
#   "consumer": {
#     "name": "Foo"
#   },
#   "provider": {
#     "name": "Bar"
#   },
#   "interactions": [
#     {
#       "description": "a retrieve thing request",
#       "request": {
#         "method": "get",
#         "path": "/thing"
#       },
#       "response": {
#         "status": 200,
#         "headers": {
#           "Content-Type": "application/json"
#         },
#         "body": {
#           "name": "Thing 1"
#         }
#       }
#     }
#   ],
#   "metadata": {
#     "pactSpecification": {
#       "version": "2.0.0"
#     }
#   }
# }
# HEREDOC

td = TestDataBuilder.new

td.create_consumer("Foo")
  .create_provider("Bar")
  .create_consumer_version("1", branch: "main", tag_names: ["foo", "bar"])
  .create_pact
  .create_verification(provider_version: "1", branch: "feat/x")
  .create_verification(provider_version: "3", branch: "feat/x", number: 2)
  .create_verification(provider_version: "4", branch: "main", number: 3)
  .create_verification(provider_version: "5", branch: "main", number: 4)
  .create_consumer_version("2", branch: "feat/y")
  .create_pact(json_content: td.random_json_content("Foo", "Bar"))
  .create_verification(provider_version: "11", branch: "feat/x")
  .create_verification(provider_version: "13", branch: "feat/x", number: 2)
  .create_verification(provider_version: "14", branch: "main", number: 3)
  .create_verification(provider_version: "15", branch: "main", number: 4)
  .create_consumer_version("3", branch: "feat/y", tag_names: ["a", "b"])
  .create_pact(json_content: td.random_json_content("Foo", "Bar"))
