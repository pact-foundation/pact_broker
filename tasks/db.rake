require "pact_broker/tasks"

namespace :bundler do
  task :setup do
    require "rubygems"
    require "bundler/setup"
  end
end

namespace :db do

  task :spec do
    Bundler.with_clean_env do
      # todo check for ruby version
      system("cd db/test/backwards_compatibility && bundle exec rake db:check_backwards_compatibility")
      success = $?.exitstatus == 0
      exit(1) unless success
    end
  end

  task :env => ["bundler:setup"] do
    # Require RACK_ENV to be set for tasks that will be called in production
    raise "Please specify RACK_ENV" unless ENV["RACK_ENV"]
    require File.dirname(__FILE__) + "/../spec/support/test_database.rb"
  end

  task :create do
    Rake::Task["db:create:#{ENV.fetch('DATABASE_ADAPTER', 'default')}"].invoke
  end

  namespace :create do
    task :default do
    end

    task :postgres do
      puts `psql postgres -c "CREATE DATABASE pact_broker;"`
      puts `psql postgres -c "GRANT ALL PRIVILEGES ON DATABASE pact_broker TO pact_broker;"`
    end

    task :mysql do
      puts `mysql -h localhost -u root -e "CREATE DATABASE IF NOT EXISTS pact_broker"`
      puts `mysql -h localhost -u root -e "GRANT ALL PRIVILEGES ON pact_broker.* TO 'pact_broker'@'localhost' identified by 'pact_broker';"`
    end
  end

  task :drop do
    Rake::Task["db:drop:#{ENV.fetch('DATABASE_ADAPTER', 'default')}"].invoke
  end

  namespace :drop do
    desc 'Delete the dev/test database - uses RACK_ENV, defaulting to "development"'
    task :default => "db:env" do
      PactBroker::TestDatabase.delete_database_file
    end

    task :postgres do
      puts `psql postgres -c "drop DATABASE pact_broker;"`
    end

    task :mysql do
      puts `mysql -h localhost -u root -e "DROP DATABASE IF EXISTS pact_broker"`
    end
  end

  desc "Print current schema version"
  task :version => "db:env" do
    puts "Schema Version: #{PactBroker::TestDatabase.version}"
  end

  desc "Migrate the Database"
  task :migrate, [:target] => "db:env" do |_t, args|
    target = args[:target] ? args[:target].to_i : nil
    PactBroker::TestDatabase.migrate(target)
  end

  desc "Rollback database to specified version"
  task :rollback, [:target] => "db:env" do |_t, args|
    args.with_defaults(target: 0)
    PactBroker::TestDatabase.migrate(args[:target].to_i)
  end

  desc 'Prepare the test database for running specs - RACK_ENV will be hardcoded to "test"'
  task "prepare:test" => ["db:set_test_env","db:prepare_dir","db:delete","db:migrate"]

  desc 'Reset the database (rollback then migrate) - uses RACK_ENV, defaulting to "development"'
  task :reset => ["db:rollback", "db:migrate"]

  desc 'Delete the dev/test database - uses RACK_ENV, defaulting to "development"'
  task "delete" => "db:env" do
    PactBroker::TestDatabase.delete_database_file
  end

  # Private: Ensure the dev/test database directory exists
  task "prepare_dir" => "db:env" do
    PactBroker::TestDatabase.ensure_database_dir_exists
  end

  desc "Annotate the Sequel domain classes with schema information.
  Start the postgres db with script/docker/db-start.sh first and run
  bundle config set --local with pg
  bundle install
  bundle exec rake db:annotate
  "
  task :annotate do
    begin
      ENV["RACK_ENV"] = "test"
      ENV["DATABASE_ADAPTER"] = "docker_postgres"
      load "#{__dir__}/../spec/support/test_database.rb"
      PactBroker::TestDatabase.migrate
      load "tasks/database/annotate.rb"
      require "pact_broker/db"
      PactBroker::Annotate.call
    end
  end

  task "docker:start" do
    load "tasks/docker_database.rb"
    DockerDatabase.start(name: "postgres-for-pact-broker", port: "5433")
  end

  task "docker:stop" do
    load "tasks/docker_database.rb"
    DockerDatabase.stop_and_remove("postgres-for-pact-broker")
  end

  # task :create => 'db:env' do
  #   PactBroker::TestDatabase.create
  # end

  # Private
  task :set_test_env do
    ENV["RACK_ENV"] = "test"
  end

  task :set_postgres_database_adapter do
    ENV["DATABASE_ADAPTER"] = "postgres"
  end

  # Private
  task "env:nonprod" => ["bundler:setup"] do
    # Allow default RACK_ENV to be set when not in production
    RACK_ENV = ENV["RACK_ENV"] ||= "development"
  end
end

task "db:env" => "db:env:nonprod"
task "db:migrate" => "db:prepare_dir"
