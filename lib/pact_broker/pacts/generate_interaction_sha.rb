require 'digest/sha1'
require 'pact_broker/pacts/order_object'

module PactBroker
  module Pacts
    module GenerateInteractionSha
      extend OrderObject

      def self.call interaction_hash
        Digest::SHA1.hexdigest(order_object(interaction_hash).to_json)
      end

      def generate_interaction_sha(interaction_hash)
        GenerateInteractionSha.call(interaction_hash)
      end
    end
  end
end
