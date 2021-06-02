require "pact_broker/db/data_migrations/helpers"

module PactBroker
  module DB
    module DataMigrations
      class SetLatestVersionSequenceValue
        def self.call connection
          if columns_exist?(connection)
            max_order = connection[:versions].max(:order) || 0
            sequence_row = connection[:version_sequence_number].first
            if sequence_row.nil? || sequence_row[:value] <= max_order
              new_value = max_order + 100
              connection[:version_sequence_number].insert(value: new_value)
              # Make sure there is only ever one row in case there is a race condition
              connection[:version_sequence_number].exclude(value: new_value).delete
            end
          end
        end

        def self.columns_exist?(connection)
          column_exists?(connection, :versions, :order) &&
            column_exists?(connection, :version_sequence_number, :value)
        end

        def self.column_exists?(connection, table, column)
          connection.table_exists?(table) && connection.schema(table).find{|col| col.first == column }
        end
      end
    end
  end
end
