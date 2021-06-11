require "pact_broker/db/data_migrations/helpers"

module PactBroker
  module DB
    module DataMigrations
      class SetCreatedAtForLatestPactPublications
        def self.call connection
          # pact ordering goes by creation date of the consumer version
          connection[:latest_pact_publication_ids_for_consumer_versions]
          query = "UPDATE latest_pact_publication_ids_for_consumer_versions
                  SET created_at = (SELECT created_at
                    FROM versions
                    WHERE id = latest_pact_publication_ids_for_consumer_versions.consumer_version_id)
                  WHERE created_at IS NULL"
          connection.run(query)
        end

        def self.columns_exist?(connection)
          column_exists?(connection, :latest_pact_publication_ids_for_consumer_versions, :created_at) &&
            column_exists?(connection, :pact_publications, :created_at)
        end
      end
    end
  end
end
