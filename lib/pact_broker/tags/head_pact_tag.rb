require "pact_broker/dataset"

module PactBroker
  module Tags
    class HeadPactTag < Sequel::Model
      dataset_module(PactBroker::Dataset)
    end
  end
end
