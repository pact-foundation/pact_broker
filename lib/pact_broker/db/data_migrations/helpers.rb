module PactBroker
  module DB
    module DataMigrations
      module Helpers
        def column_exists?(connection, table, column)
          connection.table_exists?(table) && connection.schema(table).find{|col| col.first == column }
        end
      end
    end
  end
end
