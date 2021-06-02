module PactBroker
  module DB
    class Version
      def self.call database_connection
        if database_connection.tables.include?(:schema_migrations)
          last_migration_filename = database_connection[:schema_migrations].order(:filename).last[:filename]
          last_migration_filename.split("_", 2).first.to_i
        elsif database_connection.tables.include?(:schema_info)
          database_connection[:schema_info].first[:version]
        else
          0
        end
      end
    end
  end
end
