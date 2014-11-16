require 'pact_broker/tasks'

PactBroker::DB::MigrationTask.new do | task |
  require 'db'
  task.database_connection = DB::PACT_BROKER_DB
end

namespace :bundler do
  task :setup do
    require 'rubygems'
    require 'bundler/setup'
  end
end

namespace :db do
  task :env => ['bundler:setup'] do
    # Require RACK_ENV to be set for tasks that will be called in production
    raise "Please specify RACK_ENV" unless ENV['RACK_ENV']
    RACK_ENV = ENV['RACK_ENV']
    require File.dirname(__FILE__) + '/database.rb'
  end

  desc 'Print current schema version'
  task :version => 'db:env' do
    puts "Schema Version: #{PactBroker::Database.version}"
  end

  desc 'Migrate the Database'
  task :migrate => 'db:env' do
    PactBroker::Database.migrate
  end

  desc 'Rollback database to specified version'
  task :rollback, [:target] => 'db:env' do |t, args|
    args.with_defaults(target: 0)
    PactBroker::Database.migrate(args[:target].to_i)
  end

  desc 'Prepare the test database for running specs - RACK_ENV will be hardcoded to "test"'
  task 'prepare:test' => ['db:set_test_env','db:prepare_dir','db:delete','db:migrate']

  desc 'Reset the database (rollback then migrate) - uses RACK_ENV, defaulting to "development"'
  task :reset => ['db:rollback', 'db:migrate']

  desc 'Delete the dev/test database - uses RACK_ENV, defaulting to "development"'
  task 'delete' => 'db:env' do
    PactBroker::Database.delete_database_file
  end

  # Private: Ensure the dev/test database directory exists
  task 'prepare_dir' => 'db:env' do
    PactBroker::Database.ensure_database_dir_exists
  end

  # Private
  task :set_test_env do
    ENV['RACK_ENV'] = 'test'
  end

  # Private
  task 'env:nonprod' => ['bundler:setup'] do
    # Allow default RACK_ENV to be set when not in production
    RACK_ENV = ENV['RACK_ENV'] ||= 'development'
  end
end

task 'db:env' => 'db:env:nonprod'
task 'db:migrate' => 'db:prepare_dir'
