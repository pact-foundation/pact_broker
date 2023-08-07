require "pact_broker/api/contracts/dry_validation_errors_formatter"

module PactBroker
  module Test
    module ApiContractSupport

      # See lib/pact_broker/api/contracts/README.md
      def format_errors_the_old_way(dry_validation_result)
        PactBroker::Api::Contracts::DryValidationErrorsFormatter.format_errors(dry_validation_result.errors)
      end
    end
  end
end
