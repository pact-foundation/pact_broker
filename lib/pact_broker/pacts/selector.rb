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

      def self.all_for_tag(tag)
        Selector.new(tag: tag)
      end

      def self.from_hash hash
        Selector.new(hash)
      end

      def tag
        self[:tag]
      end

      def overall_latest?
        !!(latest? && !tag)
      end

      def latest_for_tag?
        !!(latest && tag)
      end

      def <=> other
        if overall_latest? || other.overall_latest?
          if overall_latest? == other.overall_latest?
            0
          else
            overall_latest? ? -1 : 1
          end
        elsif latest_for_tag? || other.latest_for_tag?
          if latest_for_tag? == other.latest_for_tag?
            tag <=> other.tag
          else
            latest_for_tag? ? -1 : 1
          end
        else
          tag <=> other.tag
        end
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
