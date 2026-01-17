# @api public. Used by lib/pact/provider/rspec/pact_broker_formatter.rb
module Pact
  module Matchers
    class ExtractDiffMessages

      attr_reader :diff

      def initialize diff, options = {}
        @diff = diff
      end

      def self.call diff, options = {}
        new(diff, options).call
      end

      def to_hash
        to_a
      end

      def call
        to_a
      end

      def to_s
        diff_messages(diff).join("\n")
      end

      def to_a
        diff_messages(diff)
      end

      def diff_messages obj, path = [], messages = []
        case obj
        when Hash then handle_hash obj, path, messages
        when Array then handle_array obj, path, messages
        when BaseDifference then handle_difference obj, path, messages
        when NoDiffAtIndex then nil
        else
          raise "Invalid diff, expected Hash, Array, NoDiffAtIndex or BaseDifference, found #{obj.class}"
        end
        messages
      end

      def handle_hash hash, path, messages
        hash.each_pair do | key, value |
          next_part = key =~ /\s/ ? key.inspect : key
          diff_messages value, path + [".#{next_part}"], messages
        end
      end

      def handle_array array, path, messages
        array.each_with_index do | obj, index |
          diff_messages obj, path + ["[#{index}]"], messages
        end
      end

      def handle_difference difference, path, messages
        if difference.message
          message = difference.message
          message = message.gsub("<path>", path_to_s(path))
          message = message.gsub("<parent_path>", parent_path_to_s(path))
          messages << message
        end
      end

      def path_to_s path
        "$" + path.join
      end

      def parent_path_to_s path
        path_to_s(path[0..-2])
      end

    end
  end
end