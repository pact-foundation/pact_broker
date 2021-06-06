require "pact_broker/repositories"
require "pact_broker/relationships/groupify"

module PactBroker
  module Groups
    module Service
      extend self
      extend PactBroker::Repositories
      extend PactBroker::Services

      def find_group_containing pacticipant
        groups.find { | group | group.include_pacticipant? pacticipant }
      end

      def groups
        Relationships::Groupify.call(index_service.find_all_index_items)
      end
    end
  end
end
