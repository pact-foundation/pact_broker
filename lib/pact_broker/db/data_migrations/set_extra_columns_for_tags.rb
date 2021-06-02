require "pact_broker/db/data_migrations/helpers"

module PactBroker
  module DB
    module DataMigrations
      class SetExtraColumnsForTags
        extend Helpers

        def self.call(connection)
          if columns_exist?(connection, :tags, [:version_id, :pacticipant_id]) &&
              columns_exist?(connection, :versions, [:id, :pacticipant_id])
            connection[:tags].where(pacticipant_id: nil).update(
              pacticipant_id: connection[:versions].select(:pacticipant_id)
                                .where(Sequel[:versions][:id] => Sequel[:tags][:version_id])
            )
          end

          if columns_exist?(connection, :tags, [:version_id, :version_order]) &&
              columns_exist?(connection, :versions, [:id, :order])
            connection[:tags].where(version_order: nil).update(
              version_order: connection[:versions].select(:order)
                                .where(Sequel[:versions][:id] => Sequel[:tags][:version_id])
            )
          end
        end
      end
    end
  end
end
