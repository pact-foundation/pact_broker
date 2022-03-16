require "pact_broker/pacts/verifiable_pact"

module PactBroker
  module Pacts
    describe VerifiablePact do
      describe "deduplicate" do
        let(:pact_1) { double("pact 1", consumer_name: "A", pact_version_sha: "1", consumer_version: double("consumer version", order: 1)) }
        let(:pact_2) { double("pact 2", consumer_name: "B", pact_version_sha: "1", consumer_version: double("consumer version", order: 1)) }

        let(:verifiable_pact_1) do
          VerifiablePact.new(pact_1, ["selectors1"], false, [], [], "main", false)
        end

        let(:verifiable_pact_2) do
          VerifiablePact.new(pact_2, ["selectors2"], false, [], [], "main", false)
        end

        subject { VerifiablePact.deduplicate([verifiable_pact_1, verifiable_pact_2]) }

        context "when the pact sha matches and the consumer name matches" do
          let(:pact_2) { double("pact 2", consumer_name: "A", pact_version_sha: "1", consumer_version: double("consumer version", order: 2)) }

          it "merges the two verifiable pacts" do
            expect(subject.size).to eq 1
          end

          it "merges the selectors" do
            expect(subject.first.selectors).to eq ["selectors1", "selectors2"]
          end
        end

        context "when the pact sha matches and the consumer name does not match" do
          it "does not merge the two verifiable pacts" do
            expect(subject.size).to eq 2
          end
        end
      end
    end
  end
end
