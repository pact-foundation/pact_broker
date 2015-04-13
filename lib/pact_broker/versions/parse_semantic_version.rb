require 'versionomy'

module PactBroker
  module Versions
    class ParseSemanticVersion

      def self.call string_version
        begin
          ::Versionomy.parse(string_version)
        rescue ::Versionomy::Errors::ParseError => e
          nil
        end
      end

    end
  end
end
