#!/usr/bin/env ruby

raise "Please supply database path" unless ARGV[0]

$LOAD_PATH.unshift './lib'
$LOAD_PATH.unshift './spec'
$LOAD_PATH.unshift './tasks'
ENV['RACK_ENV'] = 'development'
require 'sequel'
require 'logger'
DATABASE_CREDENTIALS = {logger: Logger.new($stdout), adapter: "sqlite", database: ARGV[0], :encoding => 'utf8'}
#DATABASE_CREDENTIALS = {adapter: "postgres", database: "pact_broker", username: 'pact_broker', password: 'pact_broker', :encoding => 'utf8'}

connection = Sequel.connect(DATABASE_CREDENTIALS)
connection.timezone = :utc
require 'pact_broker/db'
PactBroker::DB.connection = connection
require 'pact_broker'
require 'support/test_data_builder'

require 'database/table_dependency_calculator'
PactBroker::Database::TableDependencyCalculator.call(connection).each do | table_name |
  connection[table_name].delete
end

PactBroker.configuration.order_versions_by_date = true

TestDataBuilder.new
  .create_consumer("zoo-app")
  .create_provider("animal-service")
  .create_consumer_version("96327295487f71f8af70a72da820d85333ab5d3e")
  .create_consumer_version_tag("master")
  .create_consumer_version_tag("prod")
  .create_pact(created_at: DateTime.now - 4)
  .create_verification(provider_version: "a519731ba244b7c0a5de7b1c862d5949e7e5db33", success: true, tag_names: ["master", "prod"], execution_date: DateTime.now - 3)
  .create_consumer_version("955b9ea2b9eb0c8515ed94b919b0bb3be06db5b5")
  .create_consumer_version_tag("master")
  .create_pact(created_at: DateTime.now - 2)
  .create_verification(provider_version: "82b59ef5f8aef1b1abfb47c3e0004e9697d03b7e", success: false, number: 2, tag_names: ["master"], execution_date: DateTime.now - 1)
  .create_consumer_version("07247012de27131ff879c3109023942b272d2716")
  .create_consumer_version_tag("master")
  .create_pact(created_at: DateTime.now - 0.5)

#   # .create_webhook(method: 'GET', url: 'https://localhost:9393?url=${pactbroker.pactUrl}', body: '${pactbroker.pactUrl}')
# TestDataBuilder.new
#   .create_consumer("Foo")
#   .create_label("microservice")
#   .create_provider("Bar")
#   .create_label("microservice")
#   .create_webhook(method: 'GET', url: 'https://self-signed.badssl.com')
#   .create_consumer_version("1.2.100")
#   .create_environment("production")
#   .publish_pact
#   .create_verification(provider_version: "1.4.234", success: true, execution_date: DateTime.now - 15)
#   .revise_pact
#   .create_consumer_version("1.2.101")
#   .create_consumer_version_tag('prod')
#   .publish_pact
#   .create_verification(provider_version: "9.9.10", success: false, execution_date: DateTime.now - 15)
#   .create_consumer_version("1.2.102")
#   .publish_pact(created_at: (Date.today - 7).to_datetime)
#   .create_verification(provider_version: "9.9.9", success: true, execution_date: DateTime.now - 14)
#   .create_provider("Animals")
#   .create_webhook(method: 'GET', url: 'http://localhost:9393/')
#   .publish_pact(created_at: (Time.now - 140).to_datetime)
#   .create_verification(provider_version: "2.0.366", execution_date: Date.today - 2) #changed
#   .create_provider("Wiffles")
#   .publish_pact
#   .create_verification(provider_version: "3.6.100", success: false, execution_date: Date.today - 7)
#   .create_provider("Hello World App")
#   .create_consumer_version("1.2.107")
#   .publish_pact(created_at: (Date.today - 1).to_datetime)
#   .create_consumer("The Android App")
#   .create_provider("The back end")
#   .create_webhook(method: 'GET', url: 'http://localhost:9393/')
#   .create_consumer_version("1.2.106")
#   .create_consumer_version_tag("production")
#   .create_consumer_version_tag("feat-x")
#   .publish_pact
#   .create_consumer("Some other app")
#   .create_provider("A service")
#   .create_webhook(method: 'GET', url: 'http://localhost:9393/')
#   .create_triggered_webhook(status: 'success')
#   .create_webhook_execution
#   .create_webhook(method: 'POST', url: 'http://foo:9393/')
#   .create_triggered_webhook(status: 'failure')
#   .create_webhook_execution
#   .create_consumer_version("1.2.106")
#   .publish_pact(created_at: (Date.today - 26).to_datetime)
#   .create_verification(provider_version: "4.8.152", execution_date: DateTime.now)

# # TestDataBuilder.new
# #   .create_pact_with_hierarchy("A", "1", "B")
# #   .create_consumer_version_tag("master")
# #   .create_consumer_version_tag("prod")
# #   .create_verification(provider_version: "1")
# #   .create_consumer_version("2")
# #   .create_consumer_version_tag("master")
# #   .create_pact
# #   .create_verification(provider_version: "2")

# # TestDataBuilder.new
# #   .create_pact_with_hierarchy("Foo", "1", "Bar")
# #   .create_webhook(method: 'GET', url: 'http://localhost:9393', events: [{ name: 'provider_verification_published' }, {name: ''}])

