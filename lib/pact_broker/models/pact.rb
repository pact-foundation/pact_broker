
module PactBroker

  module Models
    class Pact < Sequel::Model

      #Need to work out how to do this properly!
      def consumer_version_number
        values[:consumer_version_number]
      end

      def to_s
        "Pact: provider_id=#{provider_id}"
      end

      def to_json options = {}
        json_content
      end
    end
  end
end
