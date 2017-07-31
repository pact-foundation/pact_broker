require 'pact_broker/project_root'
require 'pact_broker/db/migrate'
require 'pact_broker/db/version'
require 'sequel'
require 'yaml'

Sequel.extension :migration

module PactBroker
  module Database

    TABLES = [:labels, :webhook_executions, :config, :pacts, :pact_version_contents, :tags, :verifications, :pact_publications, :pact_versions,  :webhook_headers, :webhooks, :versions, :pacticipants].freeze

    extend self

    def migrate target = nil
      opts = target ? {target: target} : {}
      PactBroker::DB::Migrate.call(database, opts)
    end

    def version
      PactBroker::DB::Version.call(database)
    end

    def delete_database_file
      ensure_not_production
      FileUtils.rm_rf database_file_path
    end

    def ensure_database_dir_exists
      ensure_not_production
      FileUtils.mkdir_p File.dirname(database_file_path)
    end

    def drop_objects
      drop_views
      drop_tables
    end

    def drop_tables
      (TABLES + [:schema_info]).each do | table_name |
        if database.table_exists?(table_name)
          database.drop_table(table_name, cascade: psql?)
        end
      end
    end

    def drop_views
      database.views.each do | view_name |
        begin
          # checking for existance using table_exists? doesn't work in sqlite
          database.drop_view(view_name, cascade: psql?)
        rescue Sequel::DatabaseError => e
          # Cascade will have deleted some views already with pg
          raise e unless e.cause.class.name == 'PG::UndefinedTable'
        end
      end
    end

    def create
      if psql?
        system('psql postgres -c "create database pact_broker"')
        system('psql postgres -c "CREATE USER pact_broker WITH PASSWORD \'pact_broker\'"')
        system('psql postgres -c "GRANT ALL PRIVILEGES ON DATABASE pact_broker to pact_broker"')
      elsif sqlite?
        ensure_database_dir_exists
      else
        raise "Unknown database adapter #{adapter}"
      end
    end

    def recreate
      drop_tables
      create
    end

    def truncate
      TABLES.each do | table_name |
        if database.table_exists?(table_name)
          database[table_name].delete
        end
      end
    end

    def database= database
      @@database = database
    end

    def database
      @@database ||= begin
        require 'db'
        ::DB.connection_for_env env
      end
    end

    private

    def ensure_not_production
      raise "Cannot delete production database using this task" if env == 'production'
    end

    def psql?
      adapter == 'postgres'
    end

    def sqlite?
      adapter == 'sqlite'
    end

    def migrations_dir
      PactBroker.project_root.join('db','migrations')
    end

    def database_file_path
      configuration_for_env(env)['database']
    end

    def adapter
      configuration_for_env(env)['adapter']
    end

    def configuration_for_env env
      database_yml = PactBroker.project_root.join('config','database.yml')
      config = YAML.load(ERB.new(File.read(database_yml)).result)
      adapter = ENV.fetch('DATABASE_ADAPTER','default')
      config.fetch(env)[adapter]
    end

    def env
      ENV.fetch('RACK_ENV')
    end
  end
end
