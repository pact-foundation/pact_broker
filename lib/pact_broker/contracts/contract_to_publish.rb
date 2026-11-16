require "pact_broker/janus"

module PactBroker
  module Contracts
    ContractToPublish = Struct.new(:consumer_name, :provider_name, :decoded_content, :content_type, :specification, :on_conflict, :pact_version_sha, keyword_init: true) do

      def self.from_hash(hash)
        new(**hash)
      end

      # Whether the contract is stored as a pact version: a pact, or a Janus contract when the
      # janus feature is on. A contract of any other specification is not stored.
      def pact?
        specification == "pact" || (specification == PactBroker::Janus::SPECIFICATION && PactBroker::Janus.enabled?)
      end

      def merge?
        on_conflict == "merge"
      end

      def pacticipant_names
        [consumer_name, provider_name]
      end
    end
  end
end
