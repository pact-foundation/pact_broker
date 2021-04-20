require 'pact_broker/hash_refinements'

module PactBroker
  module Webhooks
    class VersionMatcher < Hash
      using PactBroker::HashRefinements

      def initialize(options = {})
        merge!(options)
      end

      def self.from_hash(hash)
        new(hash.symbolize_keys)
      end

      def branch
        self[:branch]
      end

      def branch= branch
        self[:branch] = branch
      end

      def tag
        self[:tag]
      end

      def tag= tag
        self[:tag] = tag
      end
    end
  end
end
