require 'pact_broker/db'
require 'pact_broker/json'

module PactBroker

  module Domain
    class Pact

      attr_accessor :id, :provider, :consumer_version, :consumer, :created_at, :json_content, :consumer_version_number, :revision_number, :pact_version_sha

      def initialize attributes
        attributes.each_pair do | key, value |
          self.send(key.to_s + "=", value)
        end
      end

      def consumer_name
        consumer.name
      end

      def provider_name
        provider.name
      end

      def consumer
        consumer_version.pacticipant
      end

      def consumer_version_tag_names
        consumer_version.tags.collect(&:name)
      end

      def to_s
        "Pact: consumer=#{consumer.name} provider=#{provider.name}"
      end

      def to_json options = {}
        json_content
      end

      def name
        "Pact between #{consumer.name} (v#{consumer_version_number}) and #{provider.name}"
      end

      def version_and_updated_date
        "Version #{consumer_version_number} - #{created_at.to_time.localtime.strftime("%d/%m/%Y")}"
      end

      def content_hash
        JSON.parse(json_content, PACT_PARSING_OPTIONS)
      end

      def interactions
        Array(content_hash[:interactions])
      end

      def metadata
        content_hash[:meta]
      end
    end
  end
end
