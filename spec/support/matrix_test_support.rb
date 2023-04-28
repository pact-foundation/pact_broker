require "pact_broker/api/decorators/reason_decorator"

module PactBroker
  module MatrixTestSupport

    # Print out the matrix results with the text the user would see
    def print_matrix_results(results)
      results.considered_rows.each do | row |
        puts [row.consumer_name, row.consumer_version_number, row.provider_name, row.provider_version_number].join(" ")
      end

      results.deployment_status_summary.reasons.each do | reason |
        puts reason
        puts PactBroker::Api::Decorators::ReasonDecorator.new(reason)
      end
    end
  end
end
