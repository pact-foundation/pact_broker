#
# Represents the integration relationship between a consumer and a provider
#
module PactBroker
  module Matrix
    class Integration

      attr_reader :consumer_name, :consumer_id, :provider_name, :provider_id

      def initialize consumer_id, consumer_name, provider_id, provider_name
        @consumer_id = consumer_id
        @consumer_name = consumer_name
        @provider_id = provider_id
        @provider_name = provider_name
      end

      def self.from_hash hash
        new(
          hash.fetch(:consumer_id),
          hash.fetch(:consumer_name),
          hash.fetch(:provider_id),
          hash.fetch(:provider_name)
        )
      end

      def == other
        consumer_id == other.consumer_id && provider_id == other.provider_id
      end

      def <=> other
        comparison = consumer_name <=> other.consumer_name
        return comparison if comparison != 0
        provider_name <=> other.provider_name
      end

      def to_hash
        {
          consumer_name: consumer_name,
          consumer_id: consumer_id,
          provider_name: provider_name,
          provider_id: provider_id,
        }
      end

      def pacticipant_names
        [consumer_name, provider_name]
      end

      def to_s
        "Relationship between #{consumer_name} (id=#{consumer_id}) and #{provider_name} (id=#{provider_id})"
      end
    end
  end
end
