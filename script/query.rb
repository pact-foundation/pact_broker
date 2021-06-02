#!/usr/bin/env ruby
require "benchmark"
require "sequel"
require "logger"
require "table_print"
DATABASE_CREDENTIALS = {logger: Logger.new($stdout), adapter: "sqlite", database: ARGV[0], :encoding => "utf8"}
#DATABASE_CREDENTIALS = {logger: Logger.new($stdout), adapter: "sqlite", database: "pact_broker_database_test.sqlite3", :encoding => 'utf8'}
#DATABASE_CREDENTIALS = {adapter: "postgres", database: "pact_broker", username: 'pact_broker', password: 'pact_broker', :encoding => 'utf8'}
connection = Sequel.connect(DATABASE_CREDENTIALS)
connection.timezone = :utc

time = Benchmark.measure {
  puts connection[DATA.read].to_a
}

puts time.real

__END__

select * from matrix