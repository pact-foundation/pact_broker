module PactBroker
  module Contracts
    ContractsPublicationResults = Struct.new(:pacticipant, :version, :tags, :contracts, :notices, keyword_init: true) do
      def self.from_hash(params)
        new(params)
      end
    end
  end
end
