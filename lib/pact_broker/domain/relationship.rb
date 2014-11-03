module PactBroker
  module Domain

    class Relationship

      attr_reader :consumer, :provider

      def initialize consumer, provider
        @consumer = consumer
        @provider = provider
      end

      def self.create consumer, provider
        new consumer, provider
      end

      def eq? other
        Relationship === other && other.consumer == consumer && other.provider == provider
      end

      def == other
        eq?(other)
      end

      def consumer_name
        consumer.name
      end

      def provider_name
        provider.name
      end

      def pacticipants
        [consumer, provider]
      end

      def connected? other
        (self.to_a & other.to_a).any?
      end

      def include? pacticipant
        pacticipant.id == consumer.id || pacticipant.id == provider.id
      end

      def <=> other
        comp = consumer_name <=> other.consumer_name
        return comp unless comp == 0
        provider_name <=> other.provider_name
      end

      def to_s
        "Relationship between #{consumer_name} and #{provider_name}"
      end

      def to_a
        [consumer, provider]
      end

    end
  end
end