require "pact_broker/tasks"

PactBroker::DB::MigrationTask.new do | task |
  ENV["RACK_ENV"] ||= "test"
  require "db"
  task.database_connection = DB::PACT_BROKER_DB
end

PactBroker::DB::DataMigrationTask.new do | task |
  ENV["RACK_ENV"] ||= "test"
  require "db"
  task.database_connection = DB::PACT_BROKER_DB
end

PactBroker::DB::VersionTask.new do | task |
  ENV["RACK_ENV"] ||= "test"
  require "db"
  task.database_connection = DB::PACT_BROKER_DB
end

PactBroker::DB::CleanTask.new do | task |
  ENV["RACK_ENV"] ||= "test"
  require "db"
  task.database_connection = DB::PACT_BROKER_DB
end

PactBroker::DB::DeleteOverwrittenDataTask.new do | task |
  ENV["RACK_ENV"] ||= "test"
  require "db"
  task.database_connection = DB::PACT_BROKER_DB
  task.age_in_days = 7
end
