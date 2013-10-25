db_file = File.expand_path File.join(File.dirname(__FILE__), '../../tmp/pact_broker_database_test.sqlite3')
FileUtils.rm_rf db_file
FileUtils.touch db_file

require 'simplecov' # At the top because simplecov needs to watch files being loaded
ENV['RACK_ENV'] = 'test'
RACK_ENV = 'test'