require 'pact_broker/project_root'
require 'sequel'
require 'db'

Sequel.extension :migration

module PactBroker
  module Database

    extend self

    def migrate target = nil
      opts = target ? {target: target} : {}
      Sequel::Migrator.run(database, migrations_dir, opts)
    end

    def version
      if database.tables.include?(:schema_info)
        database[:schema_info].first[:version]
      else
        0
      end
    end

    def delete_database_file
      ensure_not_production
      FileUtils.rm_rf database_file_path
    end

    def ensure_database_dir_exists
      ensure_not_production
      FileUtils.mkdir_p File.dirname(database_file_path)
    end

    private

    def ensure_not_production
      raise "Cannot delete production database using this task" if env == 'production'
    end

    def database
      ::DB.connection_for_env env
    end

    def migrations_dir
      PactBroker.project_root.join('db','migrations')
    end

    def database_file_path
      ::DB.configuration_for_env(env)['database']
    end

    def env
      ENV.fetch('RACK_ENV')
    end
  end
end
