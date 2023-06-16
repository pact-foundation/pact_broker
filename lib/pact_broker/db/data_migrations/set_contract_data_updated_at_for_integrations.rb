# Populate the newly created contract_data_updated_at date in the integrations table
# using the latest created_at date from the pact_publications or verifications tables.
module PactBroker
  module DB
    module DataMigrations
      class SetContractDataUpdatedAtForIntegrations
        def self.call(connection)
          join = {
            Sequel[:integrations][:consumer_id] => Sequel[:target][:consumer_id],
            Sequel[:integrations][:provider_id] => Sequel[:target][:provider_id]
          }

          max_created_at_for_each_integration = integrations_max_created_at(connection).from_self(alias: :target).select(:created_at).where(join)

          connection[:integrations]
            .where(contract_data_updated_at: nil)
            .update(contract_data_updated_at:  max_created_at_for_each_integration)
        end

        # @return [Sequel::Dataset] the overall max created_at from the union of the pact_publications and verifications tables,
        # for each integration keyed by consumer_id/provider_id
        def self.integrations_max_created_at(connection)
          pact_publication_max_created_at(connection)
            .union(verification_max_created_at(connection))
            .select_group(:consumer_id, :provider_id)
            .select_append{ max(:created_at).as(:created_at) }
        end

        # @return [Sequel::Dataset] the max created_at from the pact_publications table
        # for each integration keyed by consumer_id/provider_id
        def self.pact_publication_max_created_at(connection)
          connection[:pact_publications]
            .select_group(:consumer_id, :provider_id)
            .select_append{ max(:created_at).as(:created_at) }
        end

        # @return [Sequel::Dataset] the max created_at from the verifications table
        # for each integration keyed by consumer_id/provider_id
        def self.verification_max_created_at(connection)
          connection[:verifications]
            .select_group(:consumer_id, :provider_id)
            .select_append{ max(:created_at).as(:created_at) }
        end
      end
    end
  end
end
