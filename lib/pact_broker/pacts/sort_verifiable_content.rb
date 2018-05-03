require 'pact_broker/json'

module PactBroker
  module Pacts
    class SortVerifiableContent

      def self.call json
        hash = JSON.parse(json, PACT_PARSING_OPTIONS)
        verifiable_content = if hash['interactions']
          hash['interactions']
        elsif hash['messages']
          hash['messages']
        end
        order_verifiable_content(verifiable_content).to_json
      end

      def self.order_verifiable_content array
        array_with_ordered_hashes = order_hashes(array)
        array_with_ordered_hashes.sort{|a, b| a.to_json <=> b.to_json }
      end

      def self.order_hashes thing
        case thing
          when Hash then order_hash(thing)
          when Array then order_child_array(thing)
        else thing
        end
      end

      def self.order_child_array array
        array.collect{|thing| order_hashes(thing) }
      end

      def self.order_hash hash
        hash.keys.sort.each_with_object({}) do | key, new_hash |
          new_hash[key] = order_hashes(hash[key])
        end
      end
    end
  end
end
