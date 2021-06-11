require "pact_broker/db/data_migrations/helpers"

module PactBroker
  module DB
    module DataMigrations
      class SetPacticipantIdsForVerifications
        def self.call connection
          if columns_exist?(connection)
            query = "UPDATE verifications
                    SET consumer_id = (SELECT consumer_id
                      FROM pact_versions
                      WHERE id = verifications.pact_version_id),
                     provider_id = (SELECT provider_id
                      FROM pact_versions
                      WHERE id = verifications.pact_version_id)
                    WHERE consumer_id is null
                    OR provider_id is null"
            connection.run(query)
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
