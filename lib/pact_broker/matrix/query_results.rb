module PactBroker
  module Matrix
    class QueryResults < Array
      attr_reader :selectors, :options, :resolved_selectors

      def initialize rows, selectors, options, resolved_selectors
        super(rows)
        @selectors = selectors
        @resolved_selectors = resolved_selectors
        @options = options
      end

      def rows
        to_a
      end
    end
  end
end
