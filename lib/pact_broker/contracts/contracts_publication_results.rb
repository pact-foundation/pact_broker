module PactBroker
  module Contracts
    ContractsPublicationResults = Struct.new(:pacticipant, :version, :tags, :contracts, :logs) do
      def self.from_hash(params)
        new(params[:pacticipant],
          params[:version],
          params[:tags],
          params[:contracts],
          params[:logs]
        )
      end
    end
  end
end
