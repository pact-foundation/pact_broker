module Pact
  class JsonDiffer

    # Delegates to https://github.com/pact-foundation/pact-support/blob/master/lib/pact/matchers/matchers.rb#L25
    def self.call expected, actual, options = {}
      require 'pact/matchers' # avoid recursive loop between this file and pact/matchers
      ::Pact::Matchers.diff expected, actual, options
    end
  end
end
