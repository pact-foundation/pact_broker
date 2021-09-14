require "pact_broker/verifications/pseudo_branch_status"

module PactBroker
  module Verifications
    describe PseudoBranchStatus do
      describe "pseudo_branch_verification_status" do

        let(:latest_verification) { instance_double("PactBroker::Domain::Verification", failed_and_pact_pending?: failed_and_pact_pending, pact_version_sha: latest_verification_pact_version_sha, success: success) }
        let(:latest_pact) { instance_double("PactBroker::Domain::Pact", pact_version_sha: pact_pact_version_sha) }
        let(:pact_pact_version_sha) { "1234" }
        let(:latest_verification_pact_version_sha) { "1234" }
        let(:success) { true }
        let(:failed_and_pact_pending) { false }

        subject { PseudoBranchStatus.new(latest_pact, latest_verification) }

        context "when the pact is nil (used in badge resource)" do
          let(:latest_pact) { nil }
          its(:to_sym) { is_expected.to eq :never }
        end

        context "when the pact has never been verified" do
          let(:latest_verification) { nil }
          its(:to_sym) { is_expected.to eq :never }
        end

        context "when the pact has not changed since the last successful verification" do
          its(:to_sym) { is_expected.to eq :success }
        end

        context "when the pact has not changed since the last failed verification" do
          let(:success) { false }
          its(:to_sym) { is_expected.to eq :failed }
        end

        context "when the pact has not changed since the last failed verification and the pact was pending" do
          let(:success) { false }
          let(:failed_and_pact_pending) { true }

          its(:to_sym) { is_expected.to eq :failed_pending }
        end

        context "when the pact has changed since the last successful verification" do
          let(:pact_pact_version_sha) { "4566" }
          its(:to_sym) { is_expected.to eq :stale }
        end

        context "when the pact has changed since the last failed verification" do
          let(:pact_pact_version_sha) { "4566" }
          let(:success) { false }
          its(:to_sym) { is_expected.to eq :failed }
        end
      end
    end
  end
end
