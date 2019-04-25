require 'digest/sha1'
require 'pact_broker/configuration'
require 'pact_broker/pacts/sort_content'
require 'pact_broker/pacts/parse'
require 'pact_broker/pacts/content'

module PactBroker
  module Pacts
    module GenerateInteractionSha
      def self.call interaction_hash
        ordered_interaction_hash = interaction_hash.keys.sort.each_with_object({}) do | key, new_interaction_hash |
          new_interaction_hash[key] = interaction_hash[key]
        end

        Digest::SHA1.hexdigest(ordered_interaction_hash.to_json)
      end

      def generate_interaction_sha(interaction_hash)
        GenerateInteractionSha.call(interaction_hash)
      end
    end
  end
end
