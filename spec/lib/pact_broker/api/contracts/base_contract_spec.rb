require "pact_broker/api/contracts/base_contract"

module PactBroker
  module Api
    module Contracts
      describe BaseContract do

        class TestContract < BaseContract
          json do
            required(:name).filled(:string)
          end
        end

        describe ".call" do
          context "when an array is supplied" do
            subject { TestContract.call([1]) }

            it "doesn't blow up" do
              expect(subject[:name]).to eq ["is missing"]
            end
          end
        end
      end
    end
  end
end
