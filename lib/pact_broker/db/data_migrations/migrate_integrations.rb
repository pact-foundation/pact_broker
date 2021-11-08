require "pact_broker/db/data_migrations/helpers"

module PactBroker
  module DB
    module DataMigrations
      class MigrateIntegrations
        extend Helpers

        def self.call(connection)
          self_join = {
            Sequel[:pact_publications][:consumer_id] => Sequel[:existing_integrations][:consumer_id],
            Sequel[:pact_publications][:provider_id] => Sequel[:existing_integrations][:provider_id]
          }

          missing_integrations = connection
                                  .from(:pact_publications)
                                    .select(
                                      Sequel[:pact_publications][:consumer_id],
                                      Sequel[:consumer][:name].as(:consumer_name),
                                      Sequel[:pact_publications][:provider_id],
                                      Sequel[:provider][:name].as(:provider_name),
                                      Sequel[:consumer][:created_at]
                                    )
                                    .distinct
                                    .left_outer_join(:integrations, self_join, { :table_alias => :existing_integrations })
                                    .join(:pacticipants, { :id => :consumer_id }, { :table_alias => :consumer, implicit_qualifier: :pact_publications })
                                    .join(:pacticipants, { :id => :provider_id }, { :table_alias => :provider, implicit_qualifier: :pact_publications })
                                    .where(Sequel[:existing_integrations][:provider_id] => nil)

          connection
            .from(:integrations)
            .insert(
            [:consumer_id, :consumer_name, :provider_id, :provider_name, :created_at],
            missing_integrations
          )
        end
      end
    end
  end
end
