module PactBroker
  module DB
    module DataMigrations
      module Helpers
        def column_exists?(connection, table, column)
          connection.table_exists?(table) && connection.schema(table).find{|col| col.first == column }
        end

        def columns_exist?(connection, table, columns)
          columns.all?{ | column | column_exists?(connection, table, column) }
        end
      end
    end
  end
end
