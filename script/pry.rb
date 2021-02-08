#!/usr/bin/env ruby

# raise "Please supply database path" unless ARGV[0]

$LOAD_PATH.unshift './lib'
$LOAD_PATH.unshift './spec'
$LOAD_PATH.unshift './tasks'
ENV['RACK_ENV'] = 'development'
require 'sequel'
require 'logger'
#DATABASE_CREDENTIALS = {logger: Logger.new($stdout), adapter: "sqlite", database: ARGV[0], :encoding => 'utf8'}.tap { |it| puts it }
DATABASE_CREDENTIALS = {adapter: "postgres", database: "postgres", username: 'postgres', password: 'postgres', host: "localhost", :encoding => 'utf8'}

connection = Sequel.connect(DATABASE_CREDENTIALS)
connection.timezone = :utc
# Uncomment these lines to open a pry session for inspecting the database


require 'pact_broker/db'
require 'pact_broker'
require 'support/test_data_builder'
puts "about to pry"

require 'pry'; pry(binding);
puts "after pry"
