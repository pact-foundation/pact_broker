require 'forwardable'
require 'pact_broker/matrix/query_results'

module PactBroker
  module Matrix
    class QueryResultsWithDeploymentStatusSummary
      extend Forwardable

      attr_reader :query_results, :deployment_status_summary

      delegate [:selectors, :options, :resolved_selectors, :integrations] => :query_results
      delegate (Array.instance_methods - Object.instance_methods) => :rows
      delegate [:deployable?] => :deployment_status_summary


      def initialize query_results, deployment_status_summary
        @query_results = query_results
        @deployment_status_summary = deployment_status_summary
      end

      def rows
        query_results.rows
      end
    end
  end
end
