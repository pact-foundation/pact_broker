require 'pact_broker/tasks'

PactBroker::DB::MigrationTask.new do | task |
  require 'db'
  task.database_connection = DB::PACT_BROKER_DB
end

PactBroker::DB::VersionTask.new do | task |
  require 'db'
  task.database_connection = DB::PACT_BROKER_DB
end
