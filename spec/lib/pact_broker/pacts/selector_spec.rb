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
        let(:all_tagged_prod) { Selector.all_for_tag("prod") }
        let(:all_dev) { Selector.all_for_tag("dev") }
        let(:currently_deployed_to_prod) { Selector.for_currently_deployed("prod") }
        let(:currently_deployed_to_test) { Selector.for_currently_deployed("test") }
        let(:currently_supported_in_prod) { Selector.for_currently_supported("prod") }

        let(:unsorted_selectors) do
          [currently_supported_in_prod, all_tagged_prod, all_dev, currently_deployed_to_prod, all_dev_for_consumer_1, latest_for_branch_main, latest_for_tag_prod, currently_deployed_to_test, overall_latest_1, overall_latest_1, latest_for_tag_dev, all_prod_for_consumer_2, all_prod_for_consumer_1]
        end

        let(:expected_sorted_selectors) do
          [
            overall_latest_1,
            overall_latest_1,
            latest_for_branch_main,
            latest_for_tag_dev,
            latest_for_tag_prod,
            all_dev_for_consumer_1,
            all_dev,
            all_prod_for_consumer_2,
            all_prod_for_consumer_1,
            all_tagged_prod,
            currently_deployed_to_prod,
            currently_deployed_to_test,
            currently_supported_in_prod,
          ]
        end

        it "sorts the selectors" do
          expect(unsorted_selectors.sort).to eq(expected_sorted_selectors)
        end

        context "with resolved selectors" do
          let(:currently_deployed_to_prod) { Selector.for_currently_deployed("prod").resolve_for_environment(double("version", order: 1), double("environment", name: "prod", production?: true)) }
          let(:currently_deployed_to_test) { Selector.for_currently_deployed("test").resolve_for_environment(double("version", order: 1), double("environment", name: "test", production?: false)) }
          let(:currently_supported_in_prod) { Selector.for_currently_supported("prod").resolve_for_environment(double("version", order: 1), double("environment", name: "prod", production?: true)) }

          let(:expected_sorted_selectors) do
            [
              overall_latest_1,
              overall_latest_1,
              latest_for_branch_main,
              latest_for_tag_dev,
              latest_for_tag_prod,
              all_dev_for_consumer_1,
              all_dev,
              all_prod_for_consumer_2,
              all_prod_for_consumer_1,
              all_tagged_prod,
              currently_deployed_to_test,
              currently_deployed_to_prod,
              currently_supported_in_prod,
            ]
          end

          it "sorts the selectors" do
            expect(unsorted_selectors.sort).to eq(expected_sorted_selectors)
          end
        end
      end
    end
  end
end
