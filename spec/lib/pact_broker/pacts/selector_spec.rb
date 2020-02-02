require 'pact_broker/pacts/selector'

module PactBroker
  module Pacts
    describe Selector do
      describe "<=>" do
        let(:overall_latest_1) { Selector.overall_latest }
        let(:overall_latest_2) { Selector.overall_latest }
        let(:latest_for_tag_prod) { Selector.latest_for_tag('prod') }
        let(:latest_for_tag_dev) { Selector.latest_for_tag('dev') }
        let(:all_prod) { Selector.all_for_tag('prod') }
        let(:all_dev) { Selector.all_for_tag('dev') }

        let(:unsorted_selectors) do
          [all_prod, all_dev, latest_for_tag_prod, overall_latest_1, overall_latest_1, latest_for_tag_dev]
        end

        let(:expected_sorted_selectors) do
          [overall_latest_1, overall_latest_1, latest_for_tag_dev, latest_for_tag_prod, all_dev, all_prod]
        end

        it "sorts the selectors" do
          expect(unsorted_selectors.sort).to eq(expected_sorted_selectors)
        end
      end
    end
  end
end
