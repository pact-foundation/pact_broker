module PactBroker
  module DB
    module DataMigrations
      class SetPacticipantIdsForVerifications
        def self.call connection
          if columns_exist?(connection)
            ids = connection.from(:verifications)
              .select(Sequel[:verifications][:id], Sequel[:pact_versions][:consumer_id], Sequel[:pact_versions][:provider_id])
              .join(:pact_versions, {id: :provider_version_id})
              .where(Sequel[:verifications][:consumer_id] => nil)
              .or(Sequel[:verifications][:provider_id] => nil)

            ids.each do | id |
              connection.from(:verifications).where(id: id[:id]).update(consumer_id: id[:consumer_id], provider_id: id[:provider_id])
            end
          end
        end

        def self.columns_exist?(connection)
          column_exists?(connection, :verifications, :provider_id) &&
            column_exists?(connection, :verifications, :consumer_id) &&
            column_exists?(connection, :verifications, :provider_version_id) &&
            column_exists?(connection, :pact_versions, :provider_id) &&
            column_exists?(connection, :pact_versions, :consumer_id) &&
            column_exists?(connection, :pact_versions, :id)
        end

        def self.column_exists?(connection, table, column)
          connection.table_exists?(table) && connection.schema(table).find{|col| col.first == column }
        end
      end
    end
  end
end
