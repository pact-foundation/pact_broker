require 'pact/shared/jruby_support'
require 'pact/matchers/differ'
require 'pact/matchers/extract_diff_messages'

module Pact
  module Matchers

    class UnixDiffFormatter

      include JRubySupport

      MESSAGES_TITLE = "\n\nDescription of differences\n--------------------------------------"

      def initialize diff, options = {}
        @diff = diff
        @colour = options.fetch(:colour, false)
        @actual = options.fetch(:actual, {})
        @include_explanation = options.fetch(:include_explanation, true)
        @differ = Pact::Matchers::Differ.new(@colour)
        @messages = Pact::Matchers::ExtractDiffMessages.call(diff).collect{ | message| "* #{message}" }.join("\n")
      end

      def self.call diff, options = {}
        # require stops circular dependency from pact/configuration <-> pact/matchers/unix_diff_formatter
        require 'pact/configuration'
        default_options = {colour: Pact.configuration.color_enabled}
        new(diff, default_options.merge(options)).call
      end

      def call
        to_s
      end

      def to_s

        expected = generate_string(diff, :expected)
        actual = generate_string(diff, :actual)
        suffix = @include_explanation ?  key + "\n" : ''
        messages = @include_explanation ? "#{MESSAGES_TITLE}\n#{@messages}\n" : ''
        string_diff = @differ.diff_as_string(actual, expected).lstrip
        string_diff = remove_first_line(string_diff)
        string_diff = remove_comma_from_end_of_arrays(string_diff)
        suffix + string_diff + messages
      end

      private

      def handle thing, target
        case thing
        when Hash then copy_hash(thing, target)
        when Array then copy_array(thing, target)
        when Difference then copy_diff(thing, target)
        when TypeDifference then copy_diff(thing, target)
        when RegexpDifference then copy_diff(thing, target)
        when NoDiffAtIndex then copy_no_diff(thing, target)
        else copy_object(thing, target)
        end
      end

      def generate_string diff, target
        comparable = handle(diff, target)
        begin
          # Can't think of an elegant way to check if we can pretty generate other than to try it and maybe fail
          json = fix_blank_lines_in_empty_hashes JSON.pretty_generate(comparable)
          json = add_blank_lines_in_empty_hashes json
          json = add_blank_lines_in_empty_arrays json
          add_comma_to_end_of_arrays json
        rescue JSON::GeneratorError
          comparable.to_s
        end
      end

      def copy_hash hash, target
        hash.keys.each_with_object({}) do | key, new_hash |
          value = handle hash[key], target
          new_hash[key] = value unless (KeyNotFound === value || UnexpectedKey === value)
        end
      end

      def copy_array array, target
        array.each_index.each_with_object([]) do | index, new_array |
          value = handle array[index], target
          new_array[index] = value unless (UnexpectedIndex === value || IndexNotFound === value)
        end
      end

      def copy_no_diff(thing, target)
        NoDifferenceDecorator.new
      end

      def copy_diff difference, target
        if target == :actual
          handle difference.actual, target
        else
          handle difference.expected, target
        end
      end

      def copy_object object, target
        if Regexp === object
          RegexpDecorator.new(object)
        else
          object
        end
      end

      def key
        "Diff\n--------------------------------------\n" +
        "Key: " + @differ.red("-") + @differ.red(" is expected \n") +
        @differ.green("     +") + @differ.green(" is actual \n") +
        "Matching keys and values are not shown\n"
      end

      def remove_first_line string_diff
        lines = string_diff.split("\n")
        if lines[0] =~ /@@/
          lines[1..-1].join("\n")
        else
          string_diff
        end
      end


      def add_comma_to_end_of_arrays string
        string.gsub(/(\n\s*\])/, ',\1')
      end

      def remove_comma_from_end_of_arrays string
        string.gsub(/,(\n\s*\])/, '\1')
      end

      class NoDifferenceDecorator

        def to_json options = {}
          "... "
        end

      end

      class RegexpDecorator

        def initialize regexp
          @regexp = regexp
        end

        def to_json options = {}
          @regexp.inspect
        end

        def as_json
          @regexp.inspect
        end
      end

      attr_reader :diff
    end

  end
end