module PactBroker
  module Contracts
    ContractToPublish = Struct.new(:consumer_name, :provider_name, :decoded_content, :content_type, :specification, :on_conflict) do
      def self.from_hash(consumer_name: nil, provider_name: nil, decoded_content: nil, content_type: nil, specification: nil, on_conflict: nil)
        new(consumer_name, provider_name, decoded_content, content_type, specification, on_conflict)
      end

      def pact?
        specification == "pact"
      end

      def merge?
        on_conflict == "merge"
      end
    end
  end
end
