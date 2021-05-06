require 'pact_broker/json'
require 'pact_broker/pacts/order_hash_keys'

module PactBroker
  module Pacts
    class SortContent
      extend OrderHashKeys

      def self.call pact_hash
        key = verifiable_content_key_for(pact_hash)

        if key
          content = pact_hash[key]
          sorted_pact_hash = order_hash_keys(pact_hash)
          sorted_pact_hash[key] = order_verifiable_content(content)
          sorted_pact_hash
        else
          pact_hash
        end
      end

      def self.verifiable_content_key_for pact_hash
        if pact_hash['interactions']
          'interactions'
        elsif pact_hash['messages']
          'messages'
        else
          nil
        end
      end

      def self.order_verifiable_content probably_array
        # You never can tell what people will do...
        if probably_array.is_a?(Array)
          array_with_ordered_hashes = order_hash_keys(probably_array)
          array_with_ordered_hashes.sort{ |a, b| a.to_json <=> b.to_json }
        else
          probably_array
        end
      end
    end
  end
end
