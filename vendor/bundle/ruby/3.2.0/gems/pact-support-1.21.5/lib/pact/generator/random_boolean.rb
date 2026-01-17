module Pact
  module Generator
    # Boolean provides the boolean generator which will give a true or false value
    class RandomBoolean
      def can_generate?(hash)
        hash.key?('type') && hash['type'] == 'RandomBoolean'
      end

      def call(_hash, _params = nil, _example_value = nil)
        [true, false].sample
      end
    end
  end
end
