# frozen_string_literal: true

module PactBroker
  module Logging
    # Makes log values safe to serialise, so that a stray Ruby object or an
    # invalid byte sequence cannot cause an appender to drop the log entry.
    #
    # Runs on every log entry that passes the level filter, so the path for
    # already-safe values must stay cheap: valid_encoding? is checked before any
    # allocation, and safe scalars are returned as-is.
    #
    # Must never raise, and must never log - it runs inside the on_log pipeline,
    # where logging would recurse.
    module PayloadSanitizer
      MAX_DEPTH = 4
      DEBUG_MAX_DEPTH = 16
      MAX_INSPECT_LENGTH = 200
      SCRUB_REPLACEMENT = "?"
      TRUNCATION_SUFFIX = "...(truncated)"
      DEPTH_EXCEEDED = "...(max depth exceeded)"

      def self.call(value, depth = 0, max_depth: MAX_DEPTH)
        case value
        when String then sanitize_string(value)
        when Symbol, Numeric, TrueClass, FalseClass, NilClass, Time then value
        when Hash then sanitize_hash(value, depth, max_depth)
        when Array then sanitize_array(value, depth, max_depth)
        else inspect_safely(value)
        end
      rescue StandardError => e
        "unsanitizable value (#{e.class})"
      end

      def self.sanitize_string(string)
        string.valid_encoding? ? string : string.scrub(SCRUB_REPLACEMENT)
      end
      private_class_method :sanitize_string

      def self.sanitize_hash(hash, depth, max_depth)
        return DEPTH_EXCEEDED if depth >= max_depth

        hash.each_with_object({}) do |(key, value), new_hash|
          new_hash[call(key, depth + 1, max_depth: max_depth)] = call(value, depth + 1, max_depth: max_depth)
        end
      end
      private_class_method :sanitize_hash

      def self.sanitize_array(array, depth, max_depth)
        return DEPTH_EXCEEDED if depth >= max_depth

        array.collect { |value| call(value, depth + 1, max_depth: max_depth) }
      end
      private_class_method :sanitize_array

      def self.inspect_safely(value)
        truncate(sanitize_string(value.inspect))
      rescue StandardError
        "uninspectable #{value.class}"
      end
      private_class_method :inspect_safely

      def self.truncate(string)
        return string if string.length <= MAX_INSPECT_LENGTH

        string[0, MAX_INSPECT_LENGTH] + TRUNCATION_SUFFIX
      end
      private_class_method :truncate
    end
  end
end
