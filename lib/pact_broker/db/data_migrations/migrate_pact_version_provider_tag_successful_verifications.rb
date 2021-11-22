require "pact_broker/db/data_migrations/helpers"

module PactBroker
  module DB
    module DataMigrations
      class MigratePactVersionProviderTagSuccessfulVerifications
        extend Helpers

        def self.call(connection)
          successful_verifications_join = {
            Sequel[:sv][:pact_version_id] => Sequel[:verifications][:pact_version_id],
            Sequel[:sv][:provider_version_tag_name] => Sequel[:tags][:name],
            Sequel[:sv][:wip] => Sequel[:verifications][:wip]
          }

          missing_verifications = connection
                                    .select(
                                      Sequel[:verifications][:pact_version_id],
                                      Sequel[:tags][:name],
                                      Sequel[:verifications][:wip],
                                      Sequel[:verifications][:id],
                                      Sequel[:verifications][:execution_date]
                                    )
                                    .order(Sequel[:verifications][:execution_date], Sequel[:verifications][:id])
                                    .from(:verifications)
                                    .join(:tags, { Sequel[:verifications][:provider_version_id] => Sequel[:tags][:version_id] })
                                    .left_outer_join(:pact_version_provider_tag_successful_verifications, successful_verifications_join, { table_alias: :sv })
                                    .where(Sequel[:sv][:pact_version_id] => nil)
                                    .where(Sequel[:verifications][:success] => true)

          connection[:pact_version_provider_tag_successful_verifications]
            .insert_ignore
            .insert([:pact_version_id, :provider_version_tag_name, :wip, :verification_id, :execution_date], missing_verifications)
        end
      end
    end
  end
end
