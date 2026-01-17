require 'uri'
require 'pact/shared/text_differ'

module Pact
  class MultipartFormDiffer
    def self.call expected, actual, options = {}
      require 'pact/matchers' # avoid recursive loop between this file and pact/matchers
      expected_boundary = expected.split.first
      actual_boundary = actual.split.first
      actual_with_hardcoded_boundary = actual.gsub(actual_boundary, expected_boundary)
      TextDiffer.call(expected, actual_with_hardcoded_boundary, options)
    rescue StandardError
      TextDiffer.call(expected, actual, options)
    end
  end
end
