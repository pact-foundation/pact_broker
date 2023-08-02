module PactBroker
  module Contracts
    ContractsToPublish = Struct.new(:pacticipant_name, :pacticipant_version_number, :tags, :branch, :build_url, :contracts) do
      # rubocop: disable Metrics/ParameterLists
      def self.from_hash(pacticipant_name: nil, pacticipant_version_number: nil, tags: nil, branch: nil, build_url: nil, contracts: nil)
        new(pacticipant_name, pacticipant_version_number, tags, branch, build_url, contracts)
      end
      # rubocop: enable Metrics/ParameterLists

      def pacticipant_names
        contracts.flat_map(&:pacticipant_names).uniq
      end

      def provider_names
        contracts.flat_map(&:provider_name).uniq
      end

      def logging_info
        to_h.slice(:pacticipant_name, :pacticipant_version_number, :tags, :branch, :build_url).merge(provider_names: provider_names)
      end
    end
  end
end
