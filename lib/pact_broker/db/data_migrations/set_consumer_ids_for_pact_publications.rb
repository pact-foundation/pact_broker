module PactBroker
  module DB
    module DataMigrations
      class SetConsumerIdsForPactPublications
        def self.call connection
          if columns_exist?(connection)
            ids = connection.from(:pact_publications)
              .select(Sequel[:pact_publications][:id], Sequel[:versions][:pacticipant_id].as(:consumer_id))
              .join(:versions, {id: :consumer_version_id})
              .where(Sequel[:pact_publications][:consumer_id] => nil)

            ids.each do | id |
              connection.from(:pact_publications).where(id: id[:id]).update(consumer_id: id[:consumer_id])
            end
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
