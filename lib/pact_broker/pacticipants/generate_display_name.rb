require 'pact_broker/string_refinements'

module PactBroker
  module Pacticipants
    module GenerateDisplayName
      using PactBroker::StringRefinements

      def self.call(name)
        return nil if name.nil?
        name
          .to_s
          .gsub(/([A-Z])([A-Z])([a-z])/,'\1 \2\3')
          .gsub(/([a-z\d])([A-Z])(\S)/,'\1 \2\3')
          .gsub(/(\S)([\-_\s\.])(\S)/, '\1 \3')
          .gsub(/\s+/, " ")
          .strip
          .split(" ")
          .collect{ |word| word.camelcase(true) }
          .join(" ")
      end

      def generate_display_name(name)
        GenerateDisplayName.call(name)
      end
    end
  end
end
