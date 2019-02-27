
# Represents the integration relationship between a consumer and a provider in the context
# of a matrix or can-i-deploy query.
# If the required flag is set, then one of the pacticipants (consumers) specified in the HTTP query
# requires the provider. It would not be required if a provider was specified, and it had an
# integration with a consumer.

module PactBroker
  module Matrix
    class Integration

      attr_reader :consumer_name, :consumer_id, :provider_name, :provider_id

      def initialize consumer_id, consumer_name, provider_id, provider_name, required
        @consumer_id = consumer_id
        @consumer_name = consumer_name
        @provider_id = provider_id
        @provider_name = provider_name
        @required = required
      end

      def self.from_hash hash
        new(
          hash.fetch(:consumer_id),
          hash.fetch(:consumer_name),
          hash.fetch(:provider_id),
          hash.fetch(:provider_name),
          hash.fetch(:required)
        )
      end

      def required?
        @required
      end

      def == other
        consumer_id == other.consumer_id && provider_id == other.provider_id
      end

      def <=> other
        comparison = consumer_name <=> other.consumer_name
        return comparison if comparison != 0
        comparison =provider_name <=> other.provider_name
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

      def involves_consumer_with_id?(consumer_id)
        self.consumer_id == consumer_id
      end

      def involves_consumer_with_names?(consumer_names)
        consumer_names.include?(self.consumer_name)
      end

      def involves_provider_with_name?(provider_name)
        self.provider_name == provider_name
      end

      def involves_consumer_with_name?(consumer_name)
        self.consumer_name == consumer_name
      end
    end
  end
end
