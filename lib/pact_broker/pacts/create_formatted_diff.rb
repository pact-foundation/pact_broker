require 'pact/matchers'
require 'pact_broker/json'
require 'pact/matchers/embedded_diff_formatter'

module PactBroker
  module Pacts
    class CreateFormattedDiff

      extend Pact::Matchers

      def self.call pact_json_content, previous_pact_json_content
        pact_hash = JSON.load(pact_json_content, nil, PactBroker::PACT_PARSING_OPTIONS)
        previous_pact_hash = JSON.load(previous_pact_json_content, nil, PactBroker::PACT_PARSING_OPTIONS)
        difference = diff(pact_hash, previous_pact_hash)
        replace_keys Pact::Matchers::EmbeddedDiffFormatter.call(difference, colour: false)
      end

      def self.replace_keys string
        string.gsub('"EXPECTED"', '"NEW"').gsub('"ACTUAL"', '"OLD')
      end

    end
  end
end
