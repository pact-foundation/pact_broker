module PactBroker
  module Matrix
    class QueryResults < Array
      attr_reader :considered_rows, :ignored_rows, :selectors, :options, :resolved_selectors, :resolved_ignore_selectors, :integrations

      # rubocop: disable Metrics/ParameterLists
      def initialize considered_rows, ignored_rows, selectors, options, resolved_selectors, resolved_ignore_selectors, integrations
        super(considered_rows + ignored_rows)
        @considered_rows = considered_rows
        @ignored_rows = ignored_rows
        @selectors = selectors
        @options = options
        @resolved_selectors = resolved_selectors
        @resolved_ignore_selectors = resolved_ignore_selectors
        @integrations = integrations
      end
      # rubocop: enable Metrics/ParameterLists

      def rows
        to_a
      end
    end
  end
end
