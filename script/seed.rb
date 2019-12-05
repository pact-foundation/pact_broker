#!/usr/bin/env ruby

raise "Please supply database path" unless ARGV[0]

$LOAD_PATH.unshift './lib'
$LOAD_PATH.unshift './spec'
$LOAD_PATH.unshift './tasks'
ENV['RACK_ENV'] = 'development'
require 'sequel'
require 'logger'
DATABASE_CREDENTIALS = {logger: Logger.new($stdout), adapter: "sqlite", database: ARGV[0], :encoding => 'utf8'}.tap { |it| puts it }
#DATABASE_CREDENTIALS = {adapter: "postgres", database: "pact_broker", username: 'pact_broker', password: 'pact_broker', :encoding => 'utf8'}

connection = Sequel.connect(DATABASE_CREDENTIALS)
connection.timezone = :utc
# Uncomment these lines to open a pry session for inspecting the database

# require 'pry'; pry(binding);
# exit

require 'pact_broker/db'
PactBroker::DB.connection = connection
require 'pact_broker'
require 'support/test_data_builder'

require 'database/table_dependency_calculator'
PactBroker::Database::TableDependencyCalculator.call(connection).each do | table_name |
  connection[table_name].delete
end

  # .create_webhook(method: 'GET', url: 'https://localhost:9393?url=${pactbroker.pactUrl}', body: '${pactbroker.pactUrl}')

webhook_body = {
  'pactUrl' => '${pactbroker.pactUrl}',
  'verificationResultUrl' => '${pactbroker.verificationResultUrl}',
  'consumerVersionNumber' => '${pactbroker.consumerVersionNumber}',
  'providerVersionNumber' => '${pactbroker.providerVersionNumber}',
  'providerVersionTags' => '${pactbroker.providerVersionTags}',
  'consumerVersionTags' => '${pactbroker.consumerVersionTags}',
  'consumerName' => '${pactbroker.consumerName}',
  'providerName' => '${pactbroker.providerName}',
  'githubVerificationStatus' => '${pactbroker.githubVerificationStatus}'
}

  # .create_global_webhook(
  #   method: 'POST',
  #   url: "http://localhost:9292/pact-changed-webhook",
  #   body: webhook_body.to_json,
  #   username: "foo",
  #   password: "bar")
TestDataBuilder.new
  .create_global_verification_succeeded_webhook(
    method: 'POST',
    url: "http://localhost:9292/verification-published-webhook",
    body: webhook_body.to_json)
  # .create_certificate(path: 'spec/fixtures/certificates/self-signed.badssl.com.pem')
  # .create_consumer("Bethtest")
  # .create_verification_webhook(method: 'GET', url: "http://localhost:9292", body: webhook_body, username: "foo", password: "bar", headers: {"Accept" => "application/json"})
  # .create_consumer("Foo")
  # .create_label("microservice")
  # .create_provider("Bar")
  # .create_label("microservice")
  # .create_verification_webhook(method: 'GET', url: "http://example.org")
  # .create_consumer_webhook(method: 'GET', url: 'https://www.google.com.au', event_names: ['provider_verification_published'])
  # .create_provider_webhook(method: 'GET', url: 'https://theage.com.au')
  # .create_webhook(method: 'GET', url: 'https://self-signed.badssl.com')
  # .create_consumer_version("1.2.100")
  # .create_pact
  # .create_verification(provider_version: "1.4.234", success: true, execution_date: DateTime.now - 15)
  # .revise_pact
  # .create_consumer_version("1.2.101")
  # .create_consumer_version_tag('prod')
  # .create_pact
  # .create_verification(provider_version: "9.9.10", success: false, execution_date: DateTime.now - 15)
  # .create_consumer_version("1.2.102")
  # .create_pact(created_at: (Date.today - 7).to_datetime)
  # .create_verification(provider_version: "9.9.9", success: true, execution_date: DateTime.now - 14)
  # .create_provider("Animals")
  # .create_webhook(method: 'GET', url: 'http://localhost:9393/')
  # .create_pact(created_at: (Time.now - 140).to_datetime)
  # .create_verification(provider_version: "2.0.366", execution_date: Date.today - 2) #changed
  # .create_provider("Wiffles")
  # .create_pact
  # .create_verification(provider_version: "3.6.100", success: false, execution_date: Date.today - 7)
  # .create_provider("Hello World App")
  # .create_consumer_version("1.2.107")
  # .create_pact(created_at: (Date.today - 1).to_datetime)
  # .create_consumer("The Android App")
  # .create_provider("The back end")
  # .create_webhook(method: 'GET', url: 'http://localhost:9393/')
  # .create_consumer_version("1.2.106")
  # .create_consumer_version_tag("production")
  # .create_consumer_version_tag("feat-x")
  # .create_pact
  # .create_consumer("Some other app")
  # .create_provider("A service")
  # .create_webhook(method: 'GET', url: 'http://localhost:9393/')
  # .create_triggered_webhook(status: 'success')
  # .create_webhook_execution
  # .create_webhook(method: 'POST', url: 'http://foo:9393/')
  # .create_triggered_webhook(status: 'failure')
  # .create_webhook_execution
  # .create_consumer_version("1.2.106")
  # .create_pact(created_at: (Date.today - 26).to_datetime)
  # .create_verification(provider_version: "4.8.152", execution_date: DateTime.now)
