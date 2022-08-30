module PactBroker
  module DB
    class Version
      def self.call database_connection
        if database_connection.tables.include?(:schema_migrations)
          version_from_schema_migrations(database_connection)
        elsif database_connection.tables.include?(:schema_info)
          version_from_schema_info(database_connection)
        else
          0
        end
      end

      private_class_method def self.version_from_schema_migrations(database_connection)
        last_migration = database_connection[:schema_migrations].order(:filename).last
        if last_migration
          last_migration[:filename].split("_", 2).first.to_i
        else
          0
        end
      end

      private_class_method def self.version_from_schema_info(database_connection)
        schema_info = database_connection[:schema_info].first
        if schema_info
          schema_info[:version]
        else
          0
        end
      end
    end
  end
end
