require 'pact/matchers/unix_diff_formatter'
require 'pact/matchers/differ'

module Pact
  module Matchers
    class MultipartFormDiffFormatter

      def initialize diff, options = {}
        @options = options
        @body_diff = diff[:body]
        @non_body_diff = diff.reject{ |k, v| k == :body }
        @colour = options.fetch(:colour, false)
        @differ = Pact::Matchers::Differ.new(@colour)
      end

      def self.call diff, options = {}
        new(diff, options).call
      end

      def call
        Pact::Matchers::UnixDiffFormatter::MESSAGES_TITLE + "\n" + non_body_diff_string + "\n" + body_diff_string
      end

      def non_body_diff_string
        if @non_body_diff.any?
          Pact::Matchers::ExtractDiffMessages.call(@non_body_diff).collect{ | message| "* #{message}" }.join("\n")
        else
          ""
        end
      end

      def body_diff_string
        if @body_diff
          @differ.diff_as_string(@body_diff.expected, @body_diff.actual)
        else
          ""
        end
      end
    end
  end
end
