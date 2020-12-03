require 'pact_broker/db/data_migrations/helpers'

module PactBroker
  module DB
    module DataMigrations
      class SetExtraColumnsForTags
        extend Helpers

        def self.call(connection)
          if columns_exist?(connection, :tags, [:pacticipant_id, :version_id]) &&
              column_exists?(connection, :versions, [:id, :pacticipant_id])
            query = "UPDATE tags SET pacticipant_id = (SELECT pacticipant_id FROM versions v WHERE v.id = tags.version_id)"
            connection.run(query)
          end

          if columns_exist?(connection, :tags, [:version_id, :version_order]) &&
              column_exists?(connection, :versions, :order)
            connection[:tags].update(version_order: connection[:versions].select(:pacticipant_id).where(Sequel[:versions][:id] => Sequel[:tags][:version_id]))
          end
        end
      end
    end
  end
end
