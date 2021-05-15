module PactBroker
  module Contracts
    ContractsPublicationResults = Struct.new(:pacticipant, :version, :tags, :contracts, :notices) do
      def self.from_hash(params)
        new(params[:pacticipant],
          params[:version],
          params[:tags],
          params[:contracts],
          params[:notices]
        )
      end
    end
  end
end
