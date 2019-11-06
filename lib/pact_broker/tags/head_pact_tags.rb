require 'pact_broker/db'
require 'pact_broker/repositories/helpers'

module PactBroker
  module Tags
    class HeadPactTag < Sequel::Model
      dataset_module do
        include PactBroker::Repositories::Helpers
      end
    end
  end
end
