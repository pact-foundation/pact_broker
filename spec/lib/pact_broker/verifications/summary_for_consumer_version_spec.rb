require "pact_broker/verifications/summary_for_consumer_version"

module PactBroker
  module Verifications
    describe SummaryForConsumerVersion do

      let(:verifications) { [verification_1, verification_2] }
      let(:verification_1) do
        instance_double("PactBroker::Domain::Verification",
          success: true,
          provider_name: "Successful Provider"
        )
      end
      let(:verification_2) do
        instance_double("PactBroker::Domain::Verification",
          success: false,
          provider_name: "Failed Provider"
        )
      end

      let(:pact_1) { instance_double("pact", provider_name: "Successful Provider", pact_version_sha: "1") }
      let(:pact_2) { instance_double("pact", provider_name: "Failed Provider", pact_version_sha: "2") }
      let(:pact_3) { instance_double("pact", provider_name: "Unknown Provider", pact_version_sha: "3") }

      let(:pacts) do
        [pact_1, pact_2, pact_3]
      end

      subject { SummaryForConsumerVersion.new(verifications, pacts)}

      describe "#pacts_by_provider_and_sha" do
        it "indexes the pacts by their provider name and pact version sha" do
          expect(subject.pacts_by_provider_and_sha).to eq(
            ["Successful Provider", "1"] => pact_1,
            ["Failed Provider", "2"] => pact_2,
            ["Unknown Provider", "3"] => pact_3
          )
        end

        context "when the pacts for two providers share a sha" do
          let(:pact_2) { instance_double("pact", provider_name: "Failed Provider", pact_version_sha: "1") }

          it "keeps a pact for each provider" do
            expect(subject.pacts_by_provider_and_sha.values).to eq [pact_1, pact_2, pact_3]
          end
        end
      end

      describe "#provider_summary" do
        it "returns the successful providers" do
          expect(subject.provider_summary.successful).to eq ["Successful Provider"]
        end

        it "returns the failed providers" do
          expect(subject.provider_summary.failed).to eq ["Failed Provider"]
        end

        it "returns the unknown providers" do
          expect(subject.provider_summary.unknown).to eq ["Unknown Provider"]
        end
      end

      describe "success" do
        context "when all pacts have a successful verification" do
          let(:verifications) { [verification_1] }
          let(:pacts) { [[pact_1]] }
          its(:success) { is_expected.to be true }
        end

        context "when some pacts have not been verified" do
          let(:verifications) { [] }
          let(:pacts) { [[pact_1]] }
          its(:success) { is_expected.to be false }
        end

        context "when some pacts have failed verification" do
          let(:verifications) { [verification_2] }
          let(:pacts) { [[pact_2]] }
          its(:success) { is_expected.to be false }
        end

        context "when there are no verifications" do
          let(:verifications) { [] }
          let(:pacts) { [[pact_2]] }
          its(:success) { is_expected.to be false }
        end
      end
    end
  end
end
