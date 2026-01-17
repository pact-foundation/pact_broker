module Pact
  module Matchers
    class NoDiffAtIndex

      def to_json options = {}
        to_s.inspect
      end

      def to_s
        '<no difference at this index>'
      end

      def == other
        other.is_a? NoDiffAtIndex
      end
    end
  end
end
