require 'strscan'

# Ripped with appreciation from Joshua Hull's useful JsonPath gem
# https://github.com/joshbuddy/jsonpath/blob/792ff9a928998f4252692cd3c1ba378ed931a5aa/lib/jsonpath.rb
# Only including the code that Pact needs, to reduce dependencies and potential gem version clashes.

module Pact
  module MatchingRules
    class JsonPath

      attr_reader :path

      def initialize(path)
        scanner = StringScanner.new(path)
        @path = []
        while not scanner.eos?
          if token = scanner.scan(/\$/)
            @path << token
          elsif token = scanner.scan(/@/)
            @path << token
          elsif token = scanner.scan(/[:a-zA-Z0-9_-]+/)
            @path << "['#{token}']"
          elsif token = scanner.scan(/'(.*?)'/)
            @path << "[#{token}]"
          elsif token = scanner.scan(/\[/)
            count = 1
            while !count.zero?
              if t = scanner.scan(/\[/)
                token << t
                count += 1
              elsif t = scanner.scan(/\]/)
                token << t
                count -= 1
              elsif t = scanner.scan(/[^\[\]]*/)
                token << t
              end
            end
            @path << token
          elsif token = scanner.scan(/\.\./)
            @path << token
          elsif scanner.scan(/\./)
            nil
          elsif token = scanner.scan(/\*/)
            @path << token
          elsif token = scanner.scan(/[><=] \d+/)
            @path.last << token
          elsif token = scanner.scan(/./)
            @path.last << token
          end
        end
      end

      def to_s
        path.join
      end
    end
  end
end
