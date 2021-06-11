require "pact_broker/pacts/verifiable_pact_messages"
require "pact_broker/pacts/verifiable_pact"
require "pact_broker/pacts/selectors"

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
      let(:consumer_version) { double("version", number: "1234" )}

      subject { VerifiablePactMessages.new(verifiable_pact, pact_version_url) }

      describe "#inclusion_reason" do
        context "when there is one selector" do
          let(:selectors) { Selectors.create_for_overall_latest.resolve(consumer_version) }
          its(:inclusion_reason) { is_expected.to include "The pact at http://pact is being verified because the pact content belongs to the consumer version matching the following criterion:" }
        end

        context "when there is more than one selector" do
          let(:selectors) { Selectors.create_for_latest_of_each_branch(%w[main feat-x]).resolve(consumer_version) }
          its(:inclusion_reason) { is_expected.to include "The pact at http://pact is being verified because the pact content belongs to the consumer versions matching the following criteria:" }
        end


        context "when there are no head consumer tags" do
          let(:selectors) { Selectors.create_for_overall_latest.resolve(consumer_version) }
          its(:inclusion_reason) { is_expected.to include "latest version of a consumer that has a pact with Bar (1234)" }
        end

        context "when there is 1 head consumer tags" do
          let(:selectors) { Selectors.create_for_latest_of_each_tag(%w[dev]).resolve(consumer_version) }
          its(:inclusion_reason) { is_expected.to include "latest version tagged 'dev' (1234)" }
          its(:pact_description) { is_expected.to eq "Pact between Foo and Bar, consumer version 123, latest with tag dev"}
        end

        context "when there are branches" do
          let(:selectors) { Selectors.create_for_latest_of_each_branch(%w[main feat-x]).resolve(consumer_version) }
          its(:inclusion_reason) { is_expected.to include "latest version from branch 'feat-x' (1234)" }
          its(:inclusion_reason) { is_expected.to include "latest version from branch 'main' (1234)" }
          its(:pact_description) { is_expected.to eq "Pact between Foo and Bar, consumer version 123, latest from branch main, latest from branch feat-x"}
        end

        context "when there are branches and tags" do
          let(:selectors) { Selectors.new([Selector.latest_for_branch("main"), Selector.latest_for_tag("prod")]).resolve(consumer_version) }
          its(:inclusion_reason) { is_expected.to include "latest version from branch 'main' (1234)" }
          its(:inclusion_reason) { is_expected.to include "latest version tagged 'prod' (1234)" }
        end

        context "when there are 2 head consumer tags" do
          let(:selectors) { Selectors.create_for_latest_of_each_tag(%w[dev prod]).resolve(consumer_version) }
          its(:inclusion_reason) { is_expected.to include "latest version tagged 'dev' (1234)" }
          its(:inclusion_reason) { is_expected.to include "latest version tagged 'prod' (1234)" }
        end

        context "when the pact was selected by the fallback tag" do
          let(:selectors) { Selectors.new(Selector.latest_for_tag_with_fallback("feat-x", "master").resolve_for_fallback(consumer_version)) }
          its(:inclusion_reason) { is_expected.to include "latest version tagged 'master' (fallback tag used as no pact was found with tag 'feat-x') (1234)" }
        end

        context "when the pact was selected by the fallback tag" do
          let(:selectors) { Selectors.new(Selector.latest_for_branch_with_fallback("feat-x", "master").resolve_for_fallback(consumer_version)) }
          its(:inclusion_reason) { is_expected.to include "latest version from branch 'master' (fallback branch used as no pact was found from branch 'feat-x') (1234)" }
        end

        context "when the pact is a WIP pact for the specified provider tags" do
          let(:selectors) { Selectors.create_for_latest_of_each_tag(%w[feat-x]).resolve(consumer_version) }
          let(:wip) { true }
          let(:pending) { true }
          let(:pending_provider_tags) { %w[dev] }

          its(:inclusion_reason) { is_expected.to include "The pact at http://pact is being verified because it is a 'work in progress' pact (ie. it is the pact for the latest version of Foo tagged with 'feat-x' and is still in pending state)."}

          context "when the pact is a WIP pact for a consumer branch" do
            let(:selectors) { Selectors.create_for_latest_of_each_branch(%w[feat-x feat-y]).resolve(consumer_version) }

            its(:inclusion_reason) { is_expected.to include "The pact at http://pact is being verified because it is a 'work in progress' pact (ie. it is the pact for the latest versions of Foo from branches 'feat-x' and 'feat-y' (both have the same content) and is still in pending state)."}
          end

          context "when the pact is a WIP pact for a consumer branch and consumer rags" do
            let(:selectors) { Selectors.create_for_latest_of_each_branch(%w[feat-x feat-y]).resolve(consumer_version) + Selectors.create_for_latest_of_each_tag(%w[feat-z feat-w]).resolve(consumer_version) }

            its(:inclusion_reason) { is_expected.to include "it is the pact for the latest versions of Foo from branches 'feat-x' and 'feat-y' and tagged with 'feat-z' and 'feat-w' (all have the same content)"}
          end
        end

        context "when the pact is one of all versions for a tag" do
          let(:selectors) { Selectors.create_for_all_of_each_tag(%w[prod]).resolve(consumer_version) }

          its(:inclusion_reason) { is_expected.to include "all consumer versions tagged 'prod' (1234)"}
        end

        context "when the pact is one of all versions for a tag and consumer" do
          let(:selectors) { Selectors.new(Selector.all_for_tag_and_consumer("prod", "Foo")).resolve(consumer_version) }

          its(:inclusion_reason) { is_expected.to include "all Foo versions tagged 'prod' (1234)"}
        end

        context "when the pact is the latest version for a tag and consumer" do
          let(:selectors) { Selectors.new(Selector.latest_for_tag_and_consumer("prod", "Foo")).resolve(consumer_version) }

          its(:inclusion_reason) { is_expected.to include "latest version of Foo tagged 'prod' (1234)"}
        end

        context "when the pact is the latest version for a branch and consumer" do
          let(:selectors) { Selectors.new(Selector.latest_for_branch_and_consumer("main", "Foo")).resolve(consumer_version) }

          its(:inclusion_reason) { is_expected.to include "latest version of Foo from branch 'main' (1234)"}
        end

        context "when the pact is the latest version for a consumer" do
          let(:selectors) { Selectors.new(Selector.latest_for_consumer("Foo")).resolve(consumer_version) }

          its(:inclusion_reason) { is_expected.to include "latest version of Foo that has a pact with Bar (1234)"}
        end

        context "when the consumer version is currently deployed to a single environment" do
          let(:selectors) { Selectors.new(Selector.for_currently_deployed("test")).resolve(consumer_version) }

          its(:inclusion_reason) { is_expected.to include "consumer version(s) currently deployed to test (1234)"}
        end

        context "when the consumer version is currently deployed to a multiple environments" do
          let(:selectors) { Selectors.new(Selector.for_currently_deployed("dev"), Selector.for_currently_deployed("test"), Selector.for_currently_deployed("prod")).resolve(consumer_version) }

          its(:inclusion_reason) { is_expected.to include "consumer version(s) currently deployed to dev (1234), prod (1234) and test (1234)"}
        end

        context "when the currently deployed consumer version is for a consumer" do
          let(:selectors) do
            Selectors.new(
              Selector.for_currently_deployed_and_environment_and_consumer("test", "Foo"),
              Selector.for_currently_deployed_and_environment_and_consumer("prod", "Foo"),
              Selector.for_currently_deployed_and_environment_and_consumer("test", "Bar"),
              Selector.for_currently_deployed("test"),
            ).resolve(consumer_version)
          end

          its(:inclusion_reason) { is_expected.to include "version(s) of Foo currently deployed to prod (1234) and test (1234)"}
          its(:inclusion_reason) { is_expected.to include "version(s) of Bar currently deployed to test (1234)"}
          its(:inclusion_reason) { is_expected.to include "consumer version(s) currently deployed to test (1234)"}
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
