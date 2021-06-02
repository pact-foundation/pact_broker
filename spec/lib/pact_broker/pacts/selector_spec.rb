require "pact_broker/pacts/selector"

module PactBroker
  module Pacts
    describe Selector do
      describe "<=>" do
        let(:overall_latest_1) { Selector.overall_latest }
        let(:overall_latest_2) { Selector.overall_latest }
        let(:latest_for_branch_main) { Selector.latest_for_branch("main") }
        let(:latest_for_tag_prod) { Selector.latest_for_tag("prod") }
        let(:latest_for_tag_dev) { Selector.latest_for_tag("dev") }
        let(:all_prod_for_consumer_1) { Selector.all_for_tag_and_consumer("prod", "Foo") }
        let(:all_prod_for_consumer_2) { Selector.all_for_tag_and_consumer("prod", "Bar") }
        let(:all_dev_for_consumer_1) { Selector.all_for_tag_and_consumer("dev", "Bar") }
        let(:all_prod) { Selector.all_for_tag("prod") }
        let(:all_dev) { Selector.all_for_tag("dev") }
        let(:currently_deployed_to_prod) { Selector.for_currently_deployed("prod") }
        let(:currently_deployed_to_test) { Selector.for_currently_deployed("test") }

        let(:unsorted_selectors) do
          [all_prod, all_dev, currently_deployed_to_prod, all_dev_for_consumer_1, latest_for_branch_main, latest_for_tag_prod, currently_deployed_to_test, overall_latest_1, overall_latest_1, latest_for_tag_dev, all_prod_for_consumer_2, all_prod_for_consumer_1]
        end

        let(:expected_sorted_selectors) do
          [overall_latest_1, overall_latest_1, latest_for_branch_main, currently_deployed_to_prod, currently_deployed_to_test, latest_for_tag_dev, latest_for_tag_prod, all_dev_for_consumer_1, all_prod_for_consumer_2, all_prod_for_consumer_1, all_dev, all_prod]
        end

        it "sorts the selectors" do
          expect(unsorted_selectors.sort).to eq(expected_sorted_selectors)
        end
      end
    end
  end
end
