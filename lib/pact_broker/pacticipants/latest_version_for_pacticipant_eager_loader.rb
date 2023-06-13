module PactBroker
  module Pacticipants
    class LatestVersionForPacticipantEagerLoader
      def self.call(eo, **_other)
        populate_associations(eo[:rows])
      end

      def self.populate_associations(pacticipants)
        pacticipants.each { | pacticipant | pacticipant.associations[:latest_version] = nil }
        pacticipant_ids = pacticipants.collect(&:id)

        max_orders = PactBroker::Domain::Version
                      .where(pacticipant_id: pacticipant_ids)
                      .select_group(:pacticipant_id)
                      .select_append { max(order).as(latest_order) }

        max_orders_join = {
          Sequel[:max_orders][:latest_order] => Sequel[:versions][:order],
          Sequel[:max_orders][:pacticipant_id] => Sequel[:versions][:pacticipant_id]
        }

        latest_versions = PactBroker::Domain::Version
                            .select_all_qualified
                            .join(max_orders, max_orders_join, { table_alias: :max_orders})

        latest_versions.each do | version |
          pacticipant = pacticipants.find{ | p | p.id == version.pacticipant_id }
          pacticipant.associations[:latest_version] = version
        end
      end
    end
  end
end
