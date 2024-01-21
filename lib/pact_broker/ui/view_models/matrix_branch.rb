require "pact_broker/api/pact_broker_urls"
require "pact_broker/ui/helpers/url_helper"
require "pact_broker/date_helper"

module PactBroker
  module UI
    module ViewModels
      class MatrixBranch

        include PactBroker::Api::PactBrokerUrls

        def initialize branch_version, pacticipant_name
          @branch_version = branch_version
          @pacticipant_name = pacticipant_name
        end

        def name
          branch_version.branch_name
        end

        def tooltip
          if branch_version.latest?
            "This is the latest version of #{pacticipant_name} from branch \"#{branch_version.branch_name}\"."
          else
            "This version of #{pacticipant_name} is from branch \"#{branch_version.branch_name}\". A more recent version from this branch exists."
          end
        end

        def latest?
          branch_version.latest?
        end

        private

        attr_reader :branch_version, :pacticipant_name
      end
    end
  end
end
