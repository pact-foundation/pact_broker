require 'approvals/verifiers/json_verifier'

module Approvals
  module Verifier
    REGISTRY = {
      json: Verifiers::JsonVerifier,
    }

    class << self
      def for(format)
        REGISTRY[format]
      end
    end
  end
end
