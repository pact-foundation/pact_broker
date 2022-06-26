#!/usr/bin/env ruby
require "bundler/setup"
Bundler.require

require "sequel"
require "logger"
require "fileutils"
require "pact_broker/initializers/database_connection"


ENV["RACK_ENV"] = "development"

root_path = File.join(__dir__, "..", "..")
$LOAD_PATH << File.join(root_path, "lib")
$LOAD_PATH << File.join(root_path, "spec")

unless ARGV[0]
  puts "Please specify the database connection string as the first argument (eg. sqlite:////tmp/pact_broker.sqlite3 or postgres://postgres:postgres@localhost/postgres)"
  exit 1
end

database_connection_string = ARGV[0]
if database_connection_string.start_with?("sqlite")
  FileUtils.mkdir_p(File.absolute_path(File.dirname(URI(database_connection_string).path)))
end

logger = Logger.new($stdout)
logger.level = Logger::DEBUG

database_opts = {
  logger: logger,
  encoding: "utf8",
  sql_log_level: "debug"
}

puts "Connecting to #{database_connection_string}"
connection = Sequel.connect(database_connection_string, database_opts)
connection.timezone = :utc

require "pact_broker"
require "pact_broker/db"

PactBroker::DB.run_migrations(connection)

require "pact_broker/api"
require "support/test_data_builder"

require "pry"; pry(binding);

"time to pry" # need a line here or pry doesn't catch
