require 'digest/sha1'
require 'pact_broker/configuration'
require 'pact_broker/pacts/sort_verifiable_content'

module PactBroker
  module Pacts
    class CreateSha
      def self.call json_content
        if PactBroker.configuration.ignore_interaction_order
          Digest::SHA1.hexdigest(SortVerifiableContent.call(json_content))
        else
          Digest::SHA1.hexdigest(json_content)
        end
      end
    end
  end
end
