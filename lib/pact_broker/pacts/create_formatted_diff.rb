require "pact_broker/json"
require "pact_broker/unified_diff"
require "pact_broker/pacts/sort_content"
require "pact_broker/pacts/content"

module PactBroker
  module Pacts
    class CreateFormattedDiff
      def self.call pact_json_content, previous_pact_json_content, raw: false
        pact_hash = JSON.parse(pact_json_content, **PactBroker::PACT_PARSING_OPTIONS)
        previous_pact_hash = JSON.parse(previous_pact_json_content, **PactBroker::PACT_PARSING_OPTIONS)

        if !raw
          pact_hash = SortContent.call(PactBroker::Pacts::Content.from_hash(pact_hash).without_ids.to_hash)
          previous_pact_hash = SortContent.call(PactBroker::Pacts::Content.from_hash(previous_pact_hash).without_ids.to_hash)
        end

        PactBroker::UnifiedDiff.call(JSON.pretty_generate(previous_pact_hash), JSON.pretty_generate(pact_hash))
      end
    end
  end
end
