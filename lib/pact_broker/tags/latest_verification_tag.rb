require 'pact_broker/db'
require 'pact_broker/repositories/helpers'

module PactBroker
  module Tags
    # The tag associated with the latest verification for a given tag
    class LatestVerificationTag < Sequel::Model

      dataset_module do
        include PactBroker::Repositories::Helpers
      end
    end
  end
end
