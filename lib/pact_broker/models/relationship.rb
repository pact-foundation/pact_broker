module PactBroker
  module Models

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

    end
  end
end