require 'pact_broker/pacts/squash_pacts_for_verification'

module PactBroker
  module Pacts
    module SquashPactsForVerification
      describe ".call" do
        let(:head_pacts) { [pact_1, pact_2] }
        let(:head_tag_1) { "dev" }
        let(:head_tag_2) { "feat-x" }
        let(:pact_version_sha_1) { "1" }
        let(:pact_version_sha_2) { "2" }
        let(:domain_pact_1) do
          double('pact1',
            pending?: pending_1,
            select_pending_provider_version_tags: pending_provider_version_tags
          )
        end
        let(:domain_pact_2) { double('pact2', pending?: pending_2) }
        let(:pending_1) { false }
        let(:pending_2) { false }
        let(:pending_provider_version_tags) { [] }

        let(:pact_1) do
          double("HeadPact",
            tag: head_tag_1,
            pact_version_sha: pact_version_sha_1,
            pact: domain_pact_1
          )
        end

        let(:pact_2) do
          double("HeadPact",
            tag: head_tag_2,
            pact_version_sha: pact_version_sha_2,
            pact: domain_pact_2
          )
        end

        let(:provider_name) { "Bar" }
        let(:provider_version_tags) { [] }

        subject { SquashPactsForVerification.call(provider_version_tags, head_pacts) }

        context "when all of the consumer tags are not nil" do
          its(:head_consumer_tags) { is_expected.to eq %w[dev feat-x] }
          its(:overall_latest?) { is_expected.to be false }
        end

        context "when one of the consumer tags is nil" do
          let(:head_tag_2) { nil }
          its(:head_consumer_tags) { is_expected.to eq %w[dev] }
          its(:overall_latest?) { is_expected.to be true }
        end

        context "when there are no provider tags" do
          context "when the pact version is not pending" do
            its(:pending) { is_expected.to be false }
            its(:pending_provider_tags) { is_expected.to eq [] }
            its(:non_pending_provider_tags) { is_expected.to eq [] }
          end

          context "when the pact version is pending" do
            let(:pending_1) { true }
            its(:pending) { is_expected.to be true }
            its(:pending_provider_tags) { is_expected.to eq [] }
            its(:non_pending_provider_tags) { is_expected.to eq [] }
          end
        end

        context "when there are provider version tags" do
          let(:provider_version_tags) { %w[dev feat-x] }

          context "when a pact is pending for any of the provider tags" do
            let(:pending_provider_version_tags) { %w[dev] }

            its(:pending) { is_expected.to be true }
            its(:pending_provider_tags) { is_expected.to eq %w[dev] }
            its(:non_pending_provider_tags) { is_expected.to eq %w[feat-x] }
          end

          context "when a pact is not pending for any of the provider tags" do
            let(:pending_provider_version_tags) { [] }

            its(:pending) { is_expected.to be false }
            its(:pending_provider_tags) { is_expected.to eq [] }
            its(:non_pending_provider_tags) { is_expected.to eq %w[dev feat-x] }
          end
        end
      end
    end
  end
end
