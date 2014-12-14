require 'pact/matchers'
require 'pact_broker/json'
require 'pact/matchers/unix_diff_formatter'

module PactBroker
  module Pacts
    class CreateFormattedDiff

      extend Pact::Matchers

      def self.call pact_json_content, previous_pact_json_content
        pact_hash = JSON.load(pact_json_content, nil, PactBroker::PACT_PARSING_OPTIONS)
        previous_pact_hash = JSON.load(previous_pact_json_content, nil, PactBroker::PACT_PARSING_OPTIONS)
        difference = diff(previous_pact_hash, pact_hash)
        Pact::Matchers::UnixDiffFormatter.call(difference, colour: false)
      end

    end
  end
end
