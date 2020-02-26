require 'pact_broker/db/data_migrations/helpers'

module PactBroker
  module DB
    module DataMigrations
      class SetConsumerIdsForPactPublications
        def self.call connection
          if columns_exist?(connection)
            query = "UPDATE pact_publications
                    SET consumer_id = (SELECT pacticipant_id
                      FROM versions
                      WHERE id = pact_publications.consumer_version_id)
                    WHERE consumer_id is null"
            connection.run(query)
          end
        end

        def self.columns_exist?(connection)
          column_exists?(connection, :pact_publications, :consumer_id) &&
            column_exists?(connection, :pact_publications, :id) &&
            column_exists?(connection, :versions, :id) &&
            column_exists?(connection, :versions, :pacticipant_id)
        end

        def self.column_exists?(connection, table, column)
          connection.table_exists?(table) && connection.schema(table).find{|col| col.first == column }
        end
      end
    end
  end
end
