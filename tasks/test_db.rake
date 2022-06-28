require "pact_broker/tasks"

PactBroker::DB::MigrationTask.new do | task |
  ENV["RACK_ENV"] ||= "test"
  require "db"
  task.database_connection = ::DB.connection_for_test_database
end

PactBroker::DB::DataMigrationTask.new do | task |
  ENV["RACK_ENV"] ||= "test"
  require "db"
  task.database_connection = ::DB.connection_for_test_database
end

PactBroker::DB::VersionTask.new do | task |
  ENV["RACK_ENV"] ||= "test"
  require "db"
  task.database_connection = ::DB.connection_for_test_database
end

PactBroker::DB::CleanTask.new do | task |
  ENV["RACK_ENV"] ||= "test"
  require "db"
  task.database_connection = ::DB.connection_for_test_database
end

PactBroker::DB::DeleteOverwrittenDataTask.new do | task |
  ENV["RACK_ENV"] ||= "test"
  require "db"
  task.database_connection = ::DB.connection_for_test_database
  task.age_in_days = 7
end
