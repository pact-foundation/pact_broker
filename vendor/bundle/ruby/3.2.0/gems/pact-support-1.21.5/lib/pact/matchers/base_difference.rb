require 'pact/matchers/expected_type'
require 'pact/matchers/actual_type'

module Pact
  module Matchers
    class BaseDifference

      attr_reader :expected, :actual, :message
      attr_writer :message

      def initialize expected, actual, message = nil
        @expected = expected
        @actual = actual
        @message = message
      end

      def any?
        true
      end

      def empty?
        false
      end

      def to_json options = {}
        as_json.to_json(options)
      end

      def to_s
        as_json.to_s
      end

      def == other
        other.class == self.class && other.expected == expected && other.actual == actual
      end

    end
  end
end