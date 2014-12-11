require 'trailblazer/operation'
require 'pact_broker/repositories'
require 'pact_broker/pacts/create_formatted_diff'

module PactBroker
  module Pacts
    class Diff < Trailblazer::Operation

      include PactBroker::Repositories

      def process params
        pact = find_pact params
        previous_distinct_pact = find_previous_distinct pact
        CreateFormattedDiff.(pact.json_content, previous_distinct_pact.json_content)
      end

      private

      def find_pact params
        pact_repository.find_pact(params.consumer_name, params.consumer_version_number, params.provider_name)
      end

      def find_previous_distinct pact
        pact_repository.find_previous_distinct_pact pact
      end

    end
  end
end
