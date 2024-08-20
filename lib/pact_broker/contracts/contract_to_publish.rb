module PactBroker
  module Contracts
    ContractToPublish = Struct.new(:consumer_name, :provider_name, :decoded_content, :content_type, :specification, :on_conflict, :pact_version_sha, keyword_init: true) do

      def self.from_hash(hash)
        new(**hash)
      end

      def pact?
        specification == "pact"
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
