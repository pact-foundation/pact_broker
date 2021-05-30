require 'fileutils'
require 'logger'
require 'sequel'
require 'pact_broker'

FileUtils.mkdir_p "pids"
FileUtils.touch "pids/#{Process.pid}"

DATABASE_CREDENTIALS = {adapter: "sqlite", database: "pact_broker_database.sqlite3", :encoding => 'utf8'}

app = PactBroker::App.new do | config |
  config.logger.formatter = proc do |severity, _datetime, _progname, msg|
    "v#{PactBroker::VERSION} #{severity} -- : #{msg}\n"
  end
  config.database_connection = Sequel.connect(DATABASE_CREDENTIALS.merge(:logger => config.logger))
  config.auto_migrate_db = true
end

PactBroker.logger.info "Running PactBroker #{PactBroker::VERSION}"

run app
