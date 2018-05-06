module PactBroker
  module DB
    module DataMigrations
      class Migration20180501
        def self.call(connection)
          if column_exists?(connection, :pact_publications, :created_at) && column_exists?(connection, :pact_publications, :updated_at)
            connection[:pact_publications].where(updated_at: nil).update(updated_at: :created_at)
          end
        end

        def self.column_exists?(connection, table_name, column_name)
          connection.schema(table_name).find { |col| col.first == table_name }
        end
      end
    end
  end
end
