module PactBroker
  module Contracts
    ContractsToPublish = Struct.new(:pacticipant_name, :version_number, :tags, :branch, :build_url, :contracts) do
      def self.from_hash(params)
        new(params[:pacticipant_name],
          params[:version_number],
          params[:tags],
          params[:branch],
          params[:build_url],
          params[:contract]
        )
      end
    end
  end
end
