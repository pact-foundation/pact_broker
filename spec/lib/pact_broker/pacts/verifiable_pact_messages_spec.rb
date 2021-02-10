require 'pact_broker/pacts/verifiable_pact_messages'
require 'pact_broker/pacts/verifiable_pact'
require 'pact_broker/pacts/selectors'

module PactBroker
  module Pacts
    describe VerifiablePactMessages do
      let(:pending_provider_tags) { [] }
      let(:non_pending_provider_tags) { [] }
      let(:provider_branch) { nil }
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
            selectors: selectors,
            provider_branch: provider_branch
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
          its(:pact_description) { is_expected.to eq "Pact between Foo and Bar, consumer version 123, latest with tag dev"}
        end

        context "when there are branches" do
          let(:selectors) { Selectors.create_for_latest_of_each_branch(%w[main feat-x]) }
          its(:inclusion_reason) { is_expected.to include "latest pact for a consumer version from branch 'feat-x', latest pact for a consumer version from branch 'main'" }
          its(:pact_description) { is_expected.to eq "Pact between Foo and Bar, consumer version 123, latest from branch main, latest from branch feat-x"}
        end

        context "when there are branches and tags" do
          let(:selectors) { Selectors.new([Selector.latest_for_branch("main"), Selector.latest_for_tag("prod")]) }
          its(:inclusion_reason) { is_expected.to include "latest pact for a consumer version from branch 'main', latest pact for a consumer version tagged 'prod'" }
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

        context "when the pact was selected by the fallback tag" do
          let(:selectors) { Selectors.new(Selector.latest_for_branch_with_fallback("feat-x", "master")) }
          its(:inclusion_reason) { is_expected.to include "latest pact for a consumer version from branch 'master' (fallback branch used as no pact was found from branch 'feat-x')" }
        end

        context "when the pact is a WIP pact for the specified provider tags" do
          let(:selectors) { Selectors.create_for_latest_of_each_tag(%w[feat-x]) }
          let(:wip) { true }
          let(:pending) { true }
          let(:pending_provider_tags) { %w[dev] }

          its(:inclusion_reason) { is_expected.to include "The pact at http://pact is being verified because it is a 'work in progress' pact (ie. it is the pact for the latest version of Foo tagged with 'feat-x' and is still in pending state)."}

          context "when the pact is a WIP pact for a consumer branch" do
            let(:selectors) { Selectors.create_for_latest_of_each_branch(%w[feat-x feat-y]) }

            its(:inclusion_reason) { is_expected.to include "The pact at http://pact is being verified because it is a 'work in progress' pact (ie. it is the pact for the latest versions of Foo from branches 'feat-x' and 'feat-y' (both have the same content) and is still in pending state)."}
          end

          context "when the pact is a WIP pact for a consumer branch and consumer rags" do
            let(:selectors) { Selectors.create_for_latest_of_each_branch(%w[feat-x feat-y]) + Selectors.create_for_latest_of_each_tag(%w[feat-z feat-w]) }

            its(:inclusion_reason) { is_expected.to include "it is the pact for the latest versions of Foo from branches 'feat-x' and 'feat-y' and tagged with 'feat-z' and 'feat-w' (all have the same content)"}
          end
        end

        context "when the pact is one of all versions for a tag" do
          let(:selectors) { Selectors.create_for_all_of_each_tag(%w[prod]) }

          its(:inclusion_reason) { is_expected.to include "The pact at http://pact is being verified because it matches the following configured selection criterion: pacts for all consumer versions tagged 'prod'"}
        end

        context "when the pact is one of all versions for a tag and consumer" do
          let(:selectors) { Selectors.new(Selector.all_for_tag_and_consumer('prod', 'Foo')) }

          its(:inclusion_reason) { is_expected.to include "The pact at http://pact is being verified because it matches the following configured selection criterion: pacts for all Foo versions tagged 'prod'"}
        end

        context "when the pact is the latest version for a tag and consumer" do
          let(:selectors) { Selectors.new(Selector.latest_for_tag_and_consumer('prod', 'Foo')) }

          its(:inclusion_reason) { is_expected.to include "The pact at http://pact is being verified because it matches the following configured selection criterion: latest pact for a version of Foo tagged 'prod'"}
        end

        context "when the pact is the latest version for a branch and consumer" do
          let(:selectors) { Selectors.new(Selector.latest_for_branch_and_consumer('main', 'Foo')) }

          its(:inclusion_reason) { is_expected.to include "The pact at http://pact is being verified because it matches the following configured selection criterion: latest pact for a version of Foo from branch 'main'"}
        end

        context "when the pact is the latest version for a consumer" do
          let(:selectors) { Selectors.new(Selector.latest_for_consumer('Foo')) }

          its(:inclusion_reason) { is_expected.to include "The pact at http://pact is being verified because it matches the following configured selection criterion: latest pact between Foo and Bar"}
        end
      end

      describe "#pending_reason" do
        context "when the pact is not pending" do
          context "when there are no non_pending_provider_tags or a provider branch" do
            its(:pending_reason) { is_expected.to include "This pact has previously been successfully verified by Bar. If this verification fails, it will fail the build." }
          end

          context "when there is 1 non_pending_provider_tag" do
            let(:non_pending_provider_tags) { %w[dev] }

            its(:pending_reason) { is_expected.to include "This pact has previously been successfully verified by a version of Bar with tag 'dev'. If this verification fails, it will fail the build."}
          end

          context "when there is a provider branch" do
            let(:provider_branch) { "main" }
            let(:non_pending_provider_tags) { %w[dev] }

            # uses branch in preference as that's what the WIP pacts logic does
            its(:pending_reason) { is_expected.to include "This pact has previously been successfully verified by a version of Bar from branch 'main'. If this verification fails, it will fail the build."}
          end
        end

        context "when the pact is pending" do
          let(:pending) { true }

          context "when there are no non_pending_provider_tags or a provider_branch" do
            its(:pending_reason) { is_expected.to include "This pact is in pending state for this version of Bar because a successful verification result for Bar has not yet been published. If this verification fails, it will not cause the overall build to fail." }
          end

          context "when there is a provider_branch" do
            let(:provider_branch) { "main" }
            its(:pending_reason) { is_expected.to include "This pact is in pending state for this version of Bar because a successful verification result for a version of Bar from branch 'main' has not yet been published. If this verification fails, it will not cause the overall build to fail." }
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
