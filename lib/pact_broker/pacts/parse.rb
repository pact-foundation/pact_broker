require "pact_broker/json"
require "json"

module PactBroker
  module Pacts
    class Parse
      def self.call(json)
        JSON.parse(json, PACT_PARSING_OPTIONS)
      end
    end
  end
end
