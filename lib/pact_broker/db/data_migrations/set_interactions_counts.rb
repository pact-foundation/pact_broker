require "pact_broker/pacts/content"

module PactBroker
  module DB
    module DataMigrations
      class SetInteractionsCounts
        def self.call(connection)
          self_join = {
            Sequel[:pact_publications][:consumer_id] => Sequel[:pp2][:consumer_id],
            Sequel[:pact_publications][:provider_id] => Sequel[:pp2][:provider_id]
          }

          pact_versions_join = {
            Sequel[:pact_versions][:id] => Sequel[:pact_publications][:pact_version_id],
            Sequel[:pact_versions][:interactions_count] => nil,
            Sequel[:pact_versions][:messages_count] => nil
          }

          base_query = connection[:pact_publications]
          base_query = base_query.select(Sequel[:pact_versions][:id], Sequel[:pact_versions][:content])

          latest_pact_publications_query = base_query.left_join(base_query.select(:consumer_id, :provider_id, :consumer_version_order), self_join, { table_alias: :pp2 } ) do
            Sequel[:pp2][:consumer_version_order] > Sequel[:pact_publications][:consumer_version_order]
          end
          .join(:pact_versions, pact_versions_join)
          .where(Sequel[:pp2][:consumer_version_order] => nil)

          latest_pact_publications_query.each do | row |
            content = PactBroker::Pacts::Content.from_json(row[:content])
            connection.from(:pact_versions)
              .where(id: row[:id])
              .update(
                messages_count: content.messages&.count || 0,
                interactions_count: content.interactions&.count || 0
              )
          end
        end
      end
    end
  end
end
