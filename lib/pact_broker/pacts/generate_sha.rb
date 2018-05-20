require 'digest/sha1'
require 'pact_broker/configuration'
require 'pact_broker/pacts/sort_content'
require 'pact_broker/pacts/parse'
require 'pact_broker/pacts/content'

module PactBroker
  module Pacts
    class GenerateSha
      def self.call json_content, options = {}
        content_for_sha = if PactBroker.configuration.base_equality_only_on_content_that_affects_verification_results
          extract_verifiable_content_for_sha(json_content)
        else
          json_content
        end
        Digest::SHA1.hexdigest(content_for_sha)
      end

      def self.extract_verifiable_content_for_sha json_content
        Content.from_json(json_content).sort.content_that_affects_verification_results.to_json
      end
    end
  end
end
