require "pact_broker/db/data_migrations/helpers"

module PactBroker
  module DB
    module DataMigrations
      class SetConsumerVersionOrderForPactPublications
        extend Helpers

        def self.call connection
          if required_columns_exist?(connection)
            connection.from(:pact_publications)
              .where(consumer_version_order: nil)
              .update(
                consumer_version_order: connection.from(:versions)
                  .select(:order)
                  .where(Sequel[:versions][:id] => Sequel[:pact_publications][:consumer_version_id])
              )
          end
        end

        def self.required_columns_exist?(connection)
          columns_exist?(connection, :pact_publications, [:consumer_version_id, :consumer_version_order]) &&
            columns_exist?(connection, :versions, [:id, :order])
        end
      end
    end
  end
end
