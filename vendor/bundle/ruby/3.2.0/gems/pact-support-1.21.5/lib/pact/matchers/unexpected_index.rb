require 'pact/matchers/difference_indicator'

module Pact
  class UnexpectedIndex < Pact::DifferenceIndicator

    def to_s
      '<item not to exist>'
    end

  end
end