require 'pact_broker/matrix/query_results'

module PactBroker
  module Matrix
    class QueryResultsWithDeploymentStatusSummary < QueryResults
      attr_reader :deployment_status_summary

      def initialize rows, selectors, options, resolved_selectors, deployment_status_summary
        super(rows, selectors, options, resolved_selectors)
        @deployment_status_summary = deployment_status_summary
      end
    end
  end
end
