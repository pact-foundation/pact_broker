require 'pact_broker/json'
require 'pact_broker/pacts/order_object'

module PactBroker
  module Pacts
    class SortContent
      def self.call pact_hash
        key = verifiable_content_key_for(pact_hash)

        if key
          content = pact_hash[key]
          sorted_pact_hash = order_object(pact_hash)
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

      def self.order_verifiable_content array
        array_with_ordered_hashes = order_object(array)
        array_with_ordered_hashes.sort{ |a, b| a.to_json <=> b.to_json }
      end

      def self.order_object thing
        OrderObject.call(thing)
      end
    end
  end
end
