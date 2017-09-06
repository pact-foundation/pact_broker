#!/usr/bin/env ruby

raise "Please supply database path" unless ARGV[0]

$LOAD_PATH.unshift './lib'
$LOAD_PATH.unshift './spec'
ENV['RACK_ENV'] = 'development'
require 'sequel'
require 'logger'
DATABASE_CREDENTIALS = {logger: Logger.new($stdout), adapter: "sqlite", database: ARGV[0], :encoding => 'utf8'}
connection = Sequel.connect(DATABASE_CREDENTIALS)
connection.timezone = :utc
require 'pact_broker/db'
PactBroker::DB.connection = connection
require 'pact_broker'
require 'support/test_data_builder'


tables_to_clean = [:labels, :webhook_executions, :triggered_webhooks, :verifications, :pact_publications, :pact_versions, :pacts, :pact_version_contents, :tags, :versions, :webhook_headers, :webhooks, :pacticipants]

tables_to_clean.each do | table_name |
  connection[table_name].delete if connection.table_exists?(table_name)
end



class TestDataBuilder
  def method_missing *args
      self
  end

  def publish_pact params = {}
    create_pact params
  end
end

# latest verifications
# TestDataBuilder.new
#   .create_consumer("Foo")
#   .create_provider("Bar")
#   .create_consumer_version("1.2.3")
#   .create_pact
#   .create_verification(provider_version: "4.5.6", success: true)
#   .create_provider("Wiffle")
#   .create_pact
#   .create_verification(provider_version: "5.6.7", success: false)
#   .create_provider("Meep")
#   .create_pact


TestDataBuilder.new
  .create_consumer("Foo")
  .create_label("microservice")
  .create_provider("Bar")
  .create_label("microservice")
  .create_webhook(method: 'GET', url: 'http://localhost:9393/')
  .create_consumer_version("1.2.100")
  .publish_pact
  .create_verification(provider_version: "1.4.234", success: true, execution_date: DateTime.now - 15)
  .revise_pact
  .create_consumer_version("1.2.101")
  .publish_pact
  .create_consumer_version("1.2.102")
  .publish_pact(created_at: (Date.today - 7).to_datetime)
  .create_provider("Animals")
  .create_webhook(method: 'GET', url: 'http://localhost:9393/')
  .publish_pact(created_at: (Time.now - 140).to_datetime)
  .create_verification(provider_version: "2.0.366", execution_date: Date.today - 2) #changed
  .create_provider("Wiffles")
  .publish_pact
  .create_verification(provider_version: "3.6.100", success: false, execution_date: Date.today - 7)
  .create_provider("Hello World App")
  .create_consumer_version("1.2.107")
  .publish_pact(created_at: (Date.today - 1).to_datetime)
  .create_consumer("The Android App")
  .create_provider("The back end")
  .create_webhook(method: 'GET', url: 'http://localhost:9393/')
  .create_consumer_version("1.2.106")
  .publish_pact
  .create_consumer("Some other app")
  .create_provider("A service")
  .create_webhook(method: 'GET', url: 'http://localhost:9393/')
  .create_triggered_webhook(status: 'success')
  .create_webhook_execution
  .create_webhook(method: 'POST', url: 'http://foo:9393/')
  .create_triggered_webhook(status: 'failure')
  .create_webhook_execution
  .create_consumer_version("1.2.106")
  .publish_pact(created_at: (Date.today - 26).to_datetime)
  .create_verification(provider_version: "4.8.152", execution_date: DateTime.now)
