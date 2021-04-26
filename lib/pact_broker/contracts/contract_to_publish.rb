module PactBroker
  module Contracts
    ContractToPublish = Struct.new(:consumer_name, :provider_name, :decoded_content, :content_type, :specification, :write_mode) do
      def self.from_hash(consumer_name: nil, provider_name: nil, decoded_content: nil, content_type: nil, specification: nil, write_mode: nil)
        new(consumer_name, provider_name, decoded_content, content_type, specification, write_mode)
      end

      def pact?
        specification == "pact"
      end

      def merge?
        write_mode == "merge"
      end
    end
  end
end
