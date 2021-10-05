require "pact_broker/api/pact_broker_urls"
require "pact_broker/ui/helpers/url_helper"
require "pact_broker/date_helper"

module PactBroker
  module UI
    module ViewDomain
      class IndexItemProviderBranchHead

        include PactBroker::Api::PactBrokerUrls

        def initialize branch_head, pacticipant_name
          @branch_head = branch_head
          @pacticipant_name = pacticipant_name
        end

        def branch_name
          branch_head.branch_name
        end

        def tooltip
          if branch_head.branch_version.auto_created
            "The latest verification is from branch \"#{branch_name}\". This branch was automatically inferred from the first tag because the Pact Broker configuration setting `use_first_tag_as_branch` was true."
          else
            "The latest verification is from branch \"#{branch_name}\"."
          end
        end

        def latest?
          true
        end

        private

        attr_reader :branch_head, :pacticipant_name
      end
    end
  end
end
