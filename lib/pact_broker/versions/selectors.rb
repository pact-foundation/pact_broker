
module PactBroker
  module Versions
    class Selectors < Array
      def initialize *selectors
        super([*selectors].flatten)
      end

      def + other
        Selectors.new(super)
      end

      def sort
        Selectors.new(super)
      end
    end
  end
end
