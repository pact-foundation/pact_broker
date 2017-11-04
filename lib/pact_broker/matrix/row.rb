require 'pact_broker/repositories/helpers'

module PactBroker
  module Matrix
    class Row < Sequel::Model
      set_dataset(:matrix)

      dataset_module do
        include PactBroker::Repositories::Helpers
      end
    end
  end
end
