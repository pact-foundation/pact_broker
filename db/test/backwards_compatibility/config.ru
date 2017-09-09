require 'fileutils'
require 'logger'
require 'sequel'
require 'pact_broker'

FileUtils.mkdir_p "pids"
FileUtils.touch "pids/#{Process.pid}"

DATABASE_CREDENTIALS = {adapter: "sqlite", database: "pact_broker_database.sqlite3", :encoding => 'utf8'}

app = PactBroker::App.new do | config |
  config.database_connection = Sequel.connect(DATABASE_CREDENTIALS.merge(:logger => config.logger))
  config.auto_migrate_db = true
end

run app
