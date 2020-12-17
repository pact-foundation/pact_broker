module PactBroker
  module Pacts
    class Selector < Hash
      def initialize(options = {})
        merge!(options)
      end

      def resolve(consumer_version)
        ResolvedSelector.new(self.to_h, consumer_version)
      end

      def tag= tag
        self[:tag] = tag
      end

      def latest= latest
        self[:latest] = latest
      end

      def latest
        self[:latest]
      end

      def fallback_tag= fallback_tag
        self[:fallback_tag] = fallback_tag
      end

      def fallback_tag
        self[:fallback_tag]
      end

      def consumer= consumer
        self[:consumer] = consumer
      end

      def consumer
        self[:consumer]
      end

      def self.overall_latest
        Selector.new(latest: true)
      end

      def self.latest_for_tag(tag)
        Selector.new(latest: true, tag: tag)
      end

      def self.latest_for_tag_with_fallback(tag, fallback_tag)
        Selector.new(latest: true, tag: tag, fallback_tag: fallback_tag)
      end

      def self.all_for_tag(tag)
        Selector.new(tag: tag)
      end

      def self.all_for_tag_and_consumer(tag, consumer)
        Selector.new(tag: tag, consumer: consumer)
      end

      def self.latest_for_tag_and_consumer(tag, consumer)
        Selector.new(latest: true, tag: tag, consumer: consumer)
      end

      def self.latest_for_consumer(consumer)
        Selector.new(latest: true, consumer: consumer)
      end

      def self.from_hash hash
        Selector.new(hash)
      end

      def fallback_tag?
        !!fallback_tag
      end

      def tag
        self[:tag]
      end

      def overall_latest?
        !!(latest? && !tag)
      end

      # Not sure if the fallback_tag logic is needed
      def latest_for_tag? potential_tag = nil
        if potential_tag
          !!(latest && tag == potential_tag)
        else
          !!(latest && !!tag)
        end
      end

      def all_for_tag_and_consumer?
        !!(tag && !latest? && consumer)
      end

      def all_for_tag?
        !!(tag && !latest?)
      end

      def == other
        other.class == self.class && super
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
        elsif consumer || other.consumer
          if consumer == other.consumer
            tag <=> other.tag
          else
            consumer ? -1 : 1
          end
        else
          tag <=> other.tag
        end
      end

      private

      def latest?
        !!self[:latest]
      end
    end

    class ResolvedSelector < Selector
      def initialize(options = {}, consumer_version)
        super(options.merge(consumer_version: consumer_version))
      end

      def consumer_version
        self[:consumer_version]
      end

      def == other
        super && consumer_version == other.consumer_version
      end
    end
  end
end
