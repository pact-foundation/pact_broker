require "digest/sha1"
require "pact_broker/configuration"
require "pact_broker/pacts/sort_content"
require "pact_broker/pacts/parse"
require "pact_broker/pacts/content"
require "pact_broker/logging"

module PactBroker
  module Pacts
    class GenerateSha
      include PactBroker::Logging

      # @param [String] json_content
      def self.call(json_content, _options = {})
        content_for_sha = if PactBroker.configuration.base_equality_only_on_content_that_affects_verification_results
                            extract_verifiable_content_for_sha(json_content)
                          else
                            json_content
                          end
        measure_info("Generating SHA1 hexdigest for pact", payload: { length: content_for_sha.length } ){ Digest::SHA1.hexdigest(content_for_sha) }
      end

      def self.extract_verifiable_content_for_sha(json_content)
        objects = Content.from_json(json_content)
        sorted_content = measure_info("Sorting content", payload: { length: json_content.length }){ objects.sort }
        sorted_content.content_that_affects_verification_results.to_json
      end
    end
  end
end
