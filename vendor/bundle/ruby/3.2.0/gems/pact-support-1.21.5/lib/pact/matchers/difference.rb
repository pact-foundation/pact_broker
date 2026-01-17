require 'pact/matchers/base_difference'

module Pact
  module Matchers
    class Difference < BaseDifference

      def as_json options = {}
        {:EXPECTED => expected, :ACTUAL => actual}
      end

    end
  end
end