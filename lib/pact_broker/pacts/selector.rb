module PactBroker
  module Pacts
    class Selector < Hash
      def initialize(options)
        merge!(options)
      end

      def self.overall_latest
        Selector.new(latest: true)
      end

      def self.latest_for_tag(tag)
        Selector.new(latest: true, tag: tag)
      end

      def self.one_of_tag(tag)
        Selector.new(tag: tag)
      end

      def tag
        self[:tag]
      end

      def overall_latest?
        !!(latest && !tag)
      end

      def latest_for_tag?
        !!(latest && tag)
      end

      private

      def latest?
        self[:latest]
      end

      def latest
        self[:latest]
      end
    end
  end
end
