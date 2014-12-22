require 'pact_broker/db'

module PactBroker

  module Domain
    class Pact

      attr_accessor :id, :provider, :consumer_version, :consumer, :updated_at, :created_at, :json_content, :consumer_version_number

      def initialize attributes
        attributes.each_pair do | key, value |
          self.send(key.to_s + "=", value)
        end
      end

      def consumer
        consumer_version.pacticipant
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
        "Version #{consumer_version_number} - #{updated_at.to_time.localtime.strftime("%d/%m/%Y")}"
      end
    end

  end
end
