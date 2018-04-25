#!/usr/bin/env ruby

raise "Please supply database path" unless ARGV[0]

$LOAD_PATH.unshift './lib'
$LOAD_PATH.unshift './spec'
$LOAD_PATH.unshift './tasks'
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

require 'database/table_dependency_calculator'
PactBroker::Database::TableDependencyCalculator.call(connection).each do | table_name |
  connection[table_name].delete
end

=begin

A -> B ->  C

1  s  1  f   1

      2   s  2

=end

# TestDataBuilder.new.create_pact_with_hierarchy("A", "1.2.3", "B")
#               .use_provider("B")
#               .create_version("2.0.0")
#               .create_provider("C")
#               .create_version("3.0.0")
#               .create_pact

TestDataBuilder.new
  .create_pact_with_hierarchy("A", "1", "B")
  .create_consumer_version_tag("master")
  .create_verification(provider_version: '1', success: false, execution_date: Date.today - 1 )
  .create_verification(provider_version: '1', number: 2, success: true)
  .create_verification(provider_version: '2', number: 3)
  .create_verification(provider_version: '4', number: 4)
  .create_provider_version("5")
  .use_consumer("B")
  .use_consumer_version("1")
  .create_consumer_version_tag("master")
  .create_provider("C")
  .create_pact
  .create_verification(provider_version: '1', success: false)
  .use_consumer_version("2")
  .create_pact
  .create_verification(provider_version: '2', success: true)
  .create_consumer_version("3")
  .create_pact
  .use_consumer("A")
  .create_consumer_version("2")
  .use_provider("B")
  .create_pact
  .create_verification(provider_version: '5')
  .create_pact_with_hierarchy("X", "1", "Z")
  .create_consumer_version_tag("feat-x")
  .create_verification(provider_version: '6')
  .create_consumer_version("2")
  .create_consumer_version_tag("feat-y")
  .create_pact
  .create_verification(provider_version: '7')
  .create_consumer_version("3")
  .create_consumer_version_tag("feat-x")
  .create_consumer_version_tag("feat-y")
  .create_pact

  # .create_pact_with_hierarchy("the-example-application", "391c43cae8c0e83c570c191f7324fccd67e53abc", "another-example-application")
  # .create_verification(provider_version: '391c43cae8c0e83c570c191f7324fccd67e53abc')
  # .create_verification(provider_version: '57fa24e44efc4d8aa42bb855a8217f145b5b1b5b', number: 2, success: false)
  # .create_verification(provider_version: '4', number: 3)
  # .use_consumer("another-example-application")
  # .use_consumer_version("391c43cae8c0e83c570c191f7324fccd67e53abc")
  # .create_provider("a-third-example-application")
  # .create_pact
  # .create_verification(provider_version: '391c43cae8c0e83c570c191f7324fccd67e53abc', success: false)
  # .use_consumer_version("57fa24e44efc4d8aa42bb855a8217f145b5b1b5b")
  # .create_pact
  # .create_verification(provider_version: '57fa24e44efc4d8aa42bb855a8217f145b5b1b5b', success: true)


