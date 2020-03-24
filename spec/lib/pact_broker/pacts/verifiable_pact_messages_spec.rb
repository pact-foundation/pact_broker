require 'pact_broker/pacts/verifiable_pact_messages'
require 'pact_broker/pacts/verifiable_pact'
require 'pact_broker/pacts/selectors'

module PactBroker
  module Pacts
    describe VerifiablePactMessages do
      let(:pending_provider_tags) { [] }
      let(:non_pending_provider_tags) { [] }
      let(:pending) { false }
      let(:wip) { false }
      let(:selectors) { Selectors.new }
      let(:pact_version_url) { "http://pact" }
      let(:verifiable_pact) do
        double(VerifiablePact,
            consumer_name: "Foo",
            consumer_version_number: "123",
            provider_name: "Bar",
            pending_provider_tags: pending_provider_tags,
            non_pending_provider_tags: non_pending_provider_tags,
            pending?: pending,
            wip?: wip,
            selectors: selectors
        )
      end

      subject { VerifiablePactMessages.new(verifiable_pact, pact_version_url) }

      describe "#inclusion_reason" do
        context "when there are no head consumer tags" do
          let(:selectors) { Selectors.create_for_overall_latest }
          its(:inclusion_reason) { is_expected.to include "The pact at http://pact is being verified because it matches the following configured selection criterion: latest pact between a consumer and Bar" }
        end

        context "when there is 1 head consumer tags" do
          let(:selectors) { Selectors.create_for_latest_of_each_tag(%w[dev]) }
          its(:inclusion_reason) { is_expected.to include "The pact at http://pact is being verified because it matches the following configured selection criterion: latest pact for a consumer version tagged 'dev'" }
          its(:pact_description) { is_expected.to eq "Pact between Foo and Bar, consumer version 123, latest dev"}
        end

        context "when there are 2 head consumer tags" do
          let(:selectors) { Selectors.create_for_latest_of_each_tag(%w[dev prod]) }
          its(:inclusion_reason) { is_expected.to include "The pact at http://pact is being verified because it matches the following configured selection criteria: latest pact for a consumer version tagged 'dev', latest pact for a consumer version tagged 'prod' (both have the same content)" }
        end

        context "when there are 3 head consumer tags" do
          let(:selectors) { Selectors.create_for_latest_of_each_tag(%w[dev prod feat-x]) }
          its(:inclusion_reason) { is_expected.to include " (all have the same content)" }
        end

        context "when the pact was selected by the fallback tag" do
          let(:selectors) { Selectors.new(Selector.latest_for_tag_with_fallback("feat-x", "master")) }
          its(:inclusion_reason) { is_expected.to include "latest pact for a consumer version tagged 'master' (fallback tag used as no pact was found with tag 'feat-x')" }
        end

        context "when the pact is a WIP pact" do
          let(:selectors) { Selectors.create_for_latest_of_each_tag(%w[feat-x]) }
          let(:wip) { true }
          let(:pending) { true }
          let(:pending_provider_tags) { %w[dev] }

          its(:inclusion_reason) { is_expected.to include "The pact at http://pact is being verified because it is a 'work in progress' pact (ie. it is the pact for the latest version of Foo tagged with 'feat-x' and is still in pending state)."}
        end

        context "when the pact is one of all versions for a tag" do
          let(:selectors) { Selectors.create_for_all_of_each_tag(%w[prod]) }

          its(:inclusion_reason) { is_expected.to include "The pact at http://pact is being verified because it matches the following configured selection criterion: pacts for all consumer versions tagged 'prod'"}
        end

        context "when the pact is one of all versions for a tag and consumer" do
          let(:selectors) { Selectors.new(Selector.all_for_tag_and_consumer('prod', 'Foo')) }

          its(:inclusion_reason) { is_expected.to include "The pact at http://pact is being verified because it matches the following configured selection criterion: pacts for all Foo versions tagged 'prod'"}
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
              its(:pending_reason) { is_expected.to include "This pact is in pending state for this version of Bar because a successful verification result for Bar has not yet been published. If this verification fails, it will not cause the overall build to fail." }
            end
          end

          context "when there is 1 pending_provider_tag" do
            let(:pending_provider_tags) { %w[dev] }

            its(:pending_reason) { is_expected.to include "This pact is in pending state for this version of Bar because a successful verification result for a version of Bar with tag 'dev' has not yet been published. If this verification fails, it will not cause the overall build to fail." }
          end

          context "when there are 2 pending_provider_tags" do
            let(:pending_provider_tags) { %w[dev feat-x] }

            its(:pending_reason) { is_expected.to include "This pact is in pending state for this version of Bar because a successful verification result for a versions of Bar with tag 'dev' and 'feat-x' has not yet been published. If this verification fails, it will not cause the overall build to fail." }
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
