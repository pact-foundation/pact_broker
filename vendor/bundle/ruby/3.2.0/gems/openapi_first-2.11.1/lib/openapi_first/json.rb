# frozen_string_literal: true

# This tries to load MultiJson if available to keep compatibility
# with MultiJson until next major version

begin
  require 'multi_json'
  module OpenapiFirst
    # Compatibility with MultiJson
    # @visibility private
    module JSON
      ParserError = MultiJson::ParseError

      def self.parse(string)
        MultiJson.load(string)
      end

      def self.generate(object)
        MultiJson.dump(object)
      end
    end
  end
rescue LoadError
  require 'json'
end
