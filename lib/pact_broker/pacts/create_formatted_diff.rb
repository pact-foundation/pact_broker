require "pact/matchers"
require "pact_broker/json"
require "pact/matchers/unix_diff_formatter"
require "pact_broker/pacts/sort_content"
require "pact_broker/pacts/content"

module PactBroker
  module Pacts
    class CreateFormattedDiff
      extend Pact::Matchers

      def self.call pact_json_content, previous_pact_json_content, raw: false
        pact_hash = JSON.load(pact_json_content, nil, PactBroker::PACT_PARSING_OPTIONS)
        previous_pact_hash = JSON.load(previous_pact_json_content, nil, PactBroker::PACT_PARSING_OPTIONS)

        if !raw
          pact_hash = SortContent.call(PactBroker::Pacts::Content.from_hash(pact_hash).without_ids.to_hash)
          previous_pact_hash = SortContent.call(PactBroker::Pacts::Content.from_hash(previous_pact_hash).without_ids.to_hash)
        end

        difference = diff(previous_pact_hash, pact_hash)

        Pact::Matchers::UnixDiffFormatter.call(difference, colour: false, include_explanation: false)
      end
    end
  end
end
