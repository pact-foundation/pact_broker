module PactBroker
  module Contracts
    ContractsToPublish = Struct.new(:pacticipant_name, :pacticipant_version_number, :tags, :branch, :build_url, :contracts) do
      def self.from_hash(pacticipant_name: nil, pacticipant_version_number: nil, tags: nil, branch: nil, build_url: nil, contracts: nil)
        new(pacticipant_name, pacticipant_version_number, tags, branch, build_url, contracts)
      end
    end
  end
end
