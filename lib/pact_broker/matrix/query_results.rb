module PactBroker
  module Matrix
    class QueryResults < Array
      attr_reader :selectors, :options, :resolved_selectors, :integrations

      def initialize rows, selectors, options, resolved_selectors, integrations
        super(rows)
        @selectors = selectors
        @resolved_selectors = resolved_selectors
        @options = options
        @integrations = integrations
      end

      def rows
        to_a
      end
    end
  end
end
