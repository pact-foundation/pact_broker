require 'pact/errors'

module Pact
  module MockService
    class AlmostDuplicateInteractionError < Pact::Error; end

    class SameSameButDifferentError < ::Pact::Error; end
  end
end
