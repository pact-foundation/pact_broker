require "pact_broker/db/data_migrations/helpers"

module PactBroker
  module DB
    module DataMigrations
      class SetCreatedAtForLatestVerifications
        def self.call connection
          connection[:latest_verification_id_for_pact_version_and_provider_version]
          query = "UPDATE latest_verification_id_for_pact_version_and_provider_version
                  SET created_at = (SELECT created_at
                    FROM verifications
                    WHERE id = latest_verification_id_for_pact_version_and_provider_version.verification_id)
                  WHERE created_at is null"
          connection.run(query)
        end

        def self.columns_exist?(connection)
          column_exists?(connection, :latest_verification_id_for_pact_version_and_provider_version, :created_at) &&
            column_exists?(connection, :verifications, :created_at)
        end
      end
    end
  end
end
