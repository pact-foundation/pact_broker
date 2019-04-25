require 'pact_broker/json'

module PactBroker
  module Pacts
    module OrderHashKeys
      def self.call thing
        case thing
          when Hash then order_hash(thing)
          when Array then order_child_array(thing)
        else thing
        end
      end

      def self.order_child_array array
        array.collect{ |thing| call(thing) }
      end

      def self.order_hash hash
        hash.keys.sort.each_with_object({}) do | key, new_hash |
          new_hash[key] = call(hash[key])
        end
      end

      def order_hash_keys(thing)
        OrderHashKeys.call(thing)
      end
    end
  end
end
