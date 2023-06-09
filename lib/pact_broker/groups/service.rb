require "pact_broker/repositories"
require "pact_broker/domain/index_item"

module PactBroker
  module Groups
    module Service
      extend self
      extend PactBroker::Repositories
      extend PactBroker::Services

      # Returns a list of all the integrations (PactBroker::Domain::IndexItem) that are connected to the given pacticipant.
      # @param pacticipant [PactBroker::Domain::Pacticipant] the pacticipant for which to return the connected pacticipants
      # @option max_pacticipants [Integer] the maximum number of pacticipants to return, or nil for no maximum. 40 is about the most applications you can meaningfully show in the circle network diagram.
      # @return [PactBroker::Domain::Group]
      def find_group_containing(pacticipant, max_pacticipants: nil)
        PactBroker::Domain::Group.new(build_index_items(integrations_connected_to(pacticipant, max_pacticipants)))
      end

      def integrations_connected_to(pacticipant, max_pacticipants)
        PactBroker::Integrations::Integration
          .eager(:consumer, :provider)
          .where(id: ids_of_integrations_connected_to(pacticipant, max_pacticipants))
          .all
      end
      private_class_method :integrations_connected_to

      def build_index_items(integrations)
        integrations.collect do | integration |
          PactBroker::Domain::IndexItem.new(integration.consumer, integration.provider)
        end
      end
      private_class_method :build_index_items

      def ids_of_integrations_connected_to(pacticipant, max_pacticipants)
        integrations = []
        connected_pacticipants = Set.new([pacticipant.id])
        new_connected_pacticipants = Set.new([pacticipant.id])

        loop do
          new_integrations = PactBroker::Integrations::Integration.including_pacticipant_id(new_connected_pacticipants.to_a).exclude(id: integrations.collect(&:id)).all
          integrations.concat(new_integrations)
          pacticipant_ids_for_new_integrations = Set.new(new_integrations.flat_map(&:pacticipant_ids))
          new_connected_pacticipants = pacticipant_ids_for_new_integrations - connected_pacticipants
          connected_pacticipants.merge(pacticipant_ids_for_new_integrations)
          break if new_connected_pacticipants.empty? || (max_pacticipants && connected_pacticipants.size >= max_pacticipants)
        end

        integrations.collect(&:id).uniq
      end
      private_class_method :ids_of_integrations_connected_to
    end
  end
end
