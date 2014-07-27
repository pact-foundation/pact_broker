require 'pact_broker/repositories'

module PactBroker

  module Services
    module GroupService

      extend self

      extend PactBroker::Repositories

      def find_group_containing pacticipant_name

      end

    end
  end
end