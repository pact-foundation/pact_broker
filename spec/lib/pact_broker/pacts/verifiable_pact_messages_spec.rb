require 'pact_broker/pacts/verifiable_pact_messages'
require 'pact_broker/pacts/verifiable_pact'

module PactBroker
  module Pacts
    describe VerifiablePactMessages do
      let(:head_consumer_tags) { [] }
      let(:pending_provider_tags) { [] }
      let(:non_pending_provider_tags) { [] }
      let(:pending) { false }
      let(:wip) { false }
      let(:verifiable_pact) do
        double(VerifiablePact,
          head_consumer_tags: head_consumer_tags,
          consumer_name: "Foo",
          provider_name: "Bar",
          pending_provider_tags: pending_provider_tags,
          non_pending_provider_tags: non_pending_provider_tags,
          pending?: pending,
          wip?: wip
        )
      end

      subject { VerifiablePactMessages.new(verifiable_pact) }

      describe "#inclusion_reason" do
        context "when there are no head consumer tags" do
          its(:inclusion_reason) { is_expected.to include "This pact is being verified because it is the latest pact between Foo and Bar." }
        end

        context "when there is 1 head consumer tags" do
          let(:head_consumer_tags) { %w[dev] }
          its(:inclusion_reason) { is_expected.to include "This pact is being verified because it is the pact for the latest version of Foo tagged with 'dev'" }
        end

        context "when there are 2 head consumer tags" do
          let(:head_consumer_tags) { %w[dev prod] }
          its(:inclusion_reason) { is_expected.to include "This pact is being verified because it is the pact for the latest versions of Foo tagged with 'dev' and 'prod' (both have the same content)" }
        end

        context "when there are 3 head consumer tags" do
          let(:head_consumer_tags) { %w[dev prod feat-x] }
          its(:inclusion_reason) { is_expected.to include "This pact is being verified because it is the pact for the latest versions of Foo tagged with 'dev', 'prod' and 'feat-x' (all have the same content)" }
        end

        context "when there are 4 head consumer tags" do
          let(:head_consumer_tags) { %w[dev prod feat-x feat-y] }
          its(:inclusion_reason) { is_expected.to include "'dev', 'prod', 'feat-x' and 'feat-y'" }
        end

        context "when the pact is a WIP pact" do
          let(:wip) { true }
          let(:pending) { true }
          let(:head_consumer_tags) { %w[feat-x] }
          let(:pending_provider_tags) { %w[dev] }

          its(:inclusion_reason) { is_expected.to include "This pact is being verified because it is a 'work in progress' pact (ie. it is the pact for the latest version of Foo tagged with 'feat-x' and is still in pending state)."}
        end
      end

      describe "#pending_reason" do
        context "when the pact is not pending" do
          context "when there are no non_pending_provider_tags" do
            its(:pending_reason) { is_expected.to include "This pact has previously been successfully verified by Bar. If this verification fails, it will fail the build." }
          end

          context "when there is 1 non_pending_provider_tag" do
            let(:non_pending_provider_tags) { %w[dev] }

            its(:pending_reason) { is_expected.to include "This pact has previously been successfully verified by a version of Bar with tag 'dev'. If this verification fails, it will fail the build."}
          end
        end

        context "when the pact is pending" do
          let(:pending) { true }

          context "when there are no pending_provider_tags" do
            context "when there are no non_pending_provider_tags" do
              its(:pending_reason) { is_expected.to include "This pact is in pending state because it has not yet been successfully verified by Bar. If this verification fails, it will not cause the overall build to fail." }
            end
          end

          context "when there is 1 pending_provider_tag" do
            let(:pending_provider_tags) { %w[dev] }

            its(:pending_reason) { is_expected.to include "This pact is in pending state because it has not yet been successfully verified by any version of Bar with tag 'dev'. If this verification fails, it will not cause the overall build to fail." }
          end

          context "when there are 2 pending_provider_tags" do
            let(:pending_provider_tags) { %w[dev feat-x] }

            its(:pending_reason) { is_expected.to include "This pact is in pending state because it has not yet been successfully verified by any versions of Bar with tag 'dev' and 'feat-x'." }
          end

          context "when there are 3 pending_provider_tags" do
            let(:pending_provider_tags) { %w[dev feat-x feat-y] }

            its(:pending_reason) { is_expected.to include "'dev', 'feat-x' and 'feat-y'" }
          end
        end
      end
    end
  end
end
