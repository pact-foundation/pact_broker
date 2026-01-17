
module Pact
  class TextDiffer

    def self.call expected, actual, options = {}
      require 'pact/matchers' # avoid recursive loop between this file and pact/matchers
      ::Pact::Matchers.diff expected, actual, options
    end

  end
end
