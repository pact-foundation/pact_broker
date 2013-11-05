require 'pact_broker/tasks'

PactBroker::DB::MigrationTask.new do | task |
  require 'pact_broker/db'
  task.database_connection = DB::PACT_BROKER_DB
end


namespace :db do
  desc 'drop and recreate DB'
  task :recreate => [:drop, 'pact_broker:db:migrate']

  desc 'drop DB'
  task :drop do
    require 'yaml'
    puts "Removing database #{db_file}"
    FileUtils.rm_f db_file
    FileUtils.mkdir_p File.dirname(db_file)
  end

  def db_file
    @@db_file ||= YAML.load(ERB.new(File.read(File.join('./config', 'database.yml'))).result)[RACK_ENV]["database"]
  end
end