require "pact_broker/pacts/selected_pact"

module PactBroker
  module Pacts
    describe SelectedPact do
      describe ".merge" do
        let(:pact_1) { double("pact 1", consumer_version_number: "1", consumer_version: double("version", order: 1)) }
        let(:selectors_1) { Selectors.new([Selector.overall_latest]) }
        let(:selected_pact_1) { SelectedPact.new(pact_1, selectors_1) }

        let(:pact_2) { double("pact 2", consumer_version_number: "2", consumer_version: double("version", order: 2)) }
        let(:selectors_2) { Selectors.new([Selector.latest_for_tag("foo")]) }
        let(:selected_pact_2) { SelectedPact.new(pact_2, selectors_2) }

        subject { SelectedPact.merge([selected_pact_1, selected_pact_2]) }

        it "merges them" do
          expect(subject.selectors).to eq Selectors.new([Selector.overall_latest, Selector.latest_for_tag("foo")])
        end
      end
    end
  end
end
