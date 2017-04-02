require 'pact_broker/repositories'
require 'pact_broker/relationships/groupify'

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
        Relationships::Groupify.call pacticipant_service.find_relationships
      end

    end
  end
end