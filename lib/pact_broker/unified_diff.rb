require "diff/lcs"
require "diff/lcs/hunk"

module PactBroker
  # Renders the difference between two texts in unified diff format,
  # without the file header lines.
  class UnifiedDiff
    def self.call(old_text, new_text, context: 3)
      old_lines = old_text.split("\n")
      new_lines = new_text.split("\n")
      pieces = Diff::LCS.diff(old_lines, new_lines)
      return "" if pieces.empty?

      hunks = []
      length_difference = 0
      pieces.each do |piece|
        hunk = Diff::LCS::Hunk.new(old_lines, new_lines, piece, context, length_difference)
        length_difference = hunk.file_length_difference
        hunk.merge(hunks.pop) if context.positive? && hunks.last && hunk.overlaps?(hunks.last)
        hunks << hunk
      end

      hunks.collect { |hunk| hunk.diff(:unified) }.join("\n")
    end
  end
end
