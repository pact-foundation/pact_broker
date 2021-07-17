require "pact_broker/pacts/repository"

module PactBroker
  module Pacts
    describe Repository do
      describe "find_wip_pact_versions_for_provider by branch" do
        # let(:provider_tags) { %w[dev] }
        let(:provider_tags) { [] }
        let(:provider_version_branch) { "dev" }
        let(:options) { { include_wip_pacts_since: include_wip_pacts_since } }
        let(:include_wip_pacts_since) { (Date.today - 1).to_datetime }

        subject { Repository.new.find_wip_pact_versions_for_provider("bar", provider_version_branch, provider_tags, [], options) }

        context "when there are no tags or branch" do
          let(:provider_tags) { [] }
          let(:provider_version_branch) { nil }

          it "returns an empty list" do
            expect(subject).to eq []
          end
        end

        context "when there are multiple wip pacts" do
          before do
            td.create_provider("bar")
              .create_provider_version("333", branch: provider_version_branch)
              .add_day
              .create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("feat-1")
              .add_day
              .create_consumer_version("2", branch: "branch-1")
              .create_pact
              .create_pact_with_hierarchy("meep", "2", "bar")
              .create_consumer_version_tag("feat-2")
              .add_day
              .create_pact_with_hierarchy("foo", "3", "bar")
              .create_consumer_version_tag("feat-2")
              .add_day
              .create_pact_with_hierarchy("meep", "1", "bar")
              .create_consumer_version_tag("feat-1")
          end

          it "sorts them" do
            expect(subject[0].consumer_name).to eq "foo"
            expect(subject[0].consumer_version_number).to eq "1"

            expect(subject[1].consumer_name).to eq "foo"
            expect(subject[1].consumer_version_number).to eq "2"

            expect(subject[2].consumer_name).to eq "foo"
            expect(subject[2].consumer_version_number).to eq "3"

            expect(subject[3].consumer_name).to eq "meep"
            expect(subject[3].consumer_version_number).to eq "2"

            expect(subject[4].consumer_name).to eq "meep"
            expect(subject[4].consumer_version_number).to eq "1"
          end

          it "sets the selectors" do
            expect(subject[0].selectors).to eq Selectors.create_for_latest_for_tag("feat-1")
            expect(subject[1].selectors).to eq Selectors.create_for_latest_for_branch("branch-1")
            expect(subject[2].selectors).to eq Selectors.create_for_latest_for_tag("feat-2")
            expect(subject[3].selectors).to eq Selectors.create_for_latest_for_tag("feat-2")
            expect(subject[4].selectors).to eq Selectors.create_for_latest_for_tag("feat-1")
          end
        end

        context "when the latest pact for a tag has been successfully verified by the given provider branch" do
          before do
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .comment("above not included because it's not the latest prod")
              .create_consumer_version("2")
              .create_consumer_version_tag("prod")
              .create_pact
              .create_verification(provider_version: "3", branch: provider_version_branch, comment: "not included because already verified")
          end

          it "is not included" do
            expect(subject.size).to be 0
          end
        end

        context "when the latest pact for a tag has been successfully verified by the given provider tag but it was a WIP verification" do
          before do
            td.create_provider("bar")
              .create_provider_version("333", branch: provider_version_branch)
              .add_day
              .create_pact_with_hierarchy("foo", "1", "bar")
              .comment("above not included because it's not the latest")
              .create_consumer_version("2")
              .create_consumer_version_tag("feat-1")
              .create_pact
              .create_verification(wip: true, success: true, provider_version: "3", branch: provider_version_branch)
          end

          it "it is included" do
            expect(subject[0].consumer_name).to eq "foo"
            expect(subject[0].consumer_version_number).to eq "2"
          end
        end

        context "when a pact is the latest for a tag and a branch and has no successful verifications" do
          before do
            td.create_provider("bar")
              .create_provider_version("333", branch: provider_version_branch)
              .add_day
              .create_consumer("foo")
              .create_consumer_version("1", branch: "branch-1", tag_names: ["feat-1"])
              .comment("above not included because it's not the latest")
              .create_consumer_version("2", branch: "branch-1", tag_names: ["feat-1"])
              .create_pact
          end

          it "it has two selectors" do
            expect(subject.size).to eq 1
            expect(subject.first.selectors).to eq Selectors.new([Selector.latest_for_branch("branch-1"), Selector.latest_for_tag("feat-1")])
          end
        end

        context "when the latest pact for a tag has failed verification from the specified provider version branch" do
          before do
            td.create_provider("bar")
              .create_provider_version("333")
              .create_provider_version_tag("dev")
              .add_day
              .create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("feat-1")
              .create_verification(provider_version: "3", success: false, branch: provider_version_branch)
              .add_day
              .create_consumer_version("2", branch: "branch-1")
              .create_pact
              .create_verification(provider_version: "3", success: false, branch: provider_version_branch)

          end

          it "is included" do
            expect(subject.size).to be 2
          end

          it "sets the pending tags" do
            expect(subject.first.provider_branch).to eq provider_version_branch
            expect(subject.last.provider_branch).to eq provider_version_branch
          end
        end

        context "when there are no consumer tags" do
          before do
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .create_verification(provider_version: "3", success: false, branch: provider_version_branch)
          end

          it "returns an empty list" do
            expect(subject).to eq []
          end
        end

        context "when the latest pact for a tag has successful then failed verifications" do
          before do
            td.create_provider("bar")
              .create_provider_version("333")
              .create_provider_version_tag("dev")
              .add_day
              .create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("dev")
              .create_verification(provider_version: "3", success: true, branch: provider_version_branch)
              .create_verification(provider_version: "5", success: false, number: 2, branch: provider_version_branch)
          end

          it "is not included, but maybe it should be? can't really work out a scenario where this is likely to happen" do
            expect(subject).to eq []
          end
        end

        context "when the latest pact for a tag has not been verified" do
          before do
            td.create_provider("bar")
              .create_provider_version("333")
              .create_provider_version_tag("dev")
              .add_day
              .create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("feat-1")
          end

          it "is included" do
            expect(subject.size).to be 1
          end

          it "sets the pending tags" do
            expect(subject.first.provider_branch).to eq provider_version_branch
          end
        end

        context "when the provider name does not match the given provider name" do
          before do
            td.create_pact_with_hierarchy("foo", "1", "baz")
              .create_provider("bar")
          end

          it "is not included" do
            expect(subject.size).to be 0
          end
        end

        context "when the pact was published before the specified include_wip_pacts_since" do
          before do
            td.create_provider("bar")
              .create_provider_version("333", branch: provider_version_branch)
              .add_day
              .create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("prod")
          end

          let(:include_wip_pacts_since) { (Date.today + 3).to_datetime }

          it "is not included" do
            expect(subject.size).to be 0
          end
        end

        context "when the provider version tag specified does not exist yet and there are previous successful verifications from another branch" do
          before do
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("main")
              .create_verification(provider_version: "20", branch: "dev", success: true)
              .create_verification(provider_version: "21", number: 2)
          end

          let(:provider_version_branch) { "feat-new-branch" }

          it { is_expected.to be_empty }
        end

        context "when the provider version tag specified does not exist yet and there are previous failed verifications from another branch" do
          before do
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("main")
              .create_verification(provider_version: "20", branch: "dev", success: false)
              .create_verification(provider_version: "21", number: 2)
          end

          let(:provider_version_branch) { "feat-new-branch" }

          it "is included" do
            expect(subject.first.provider_branch).to eq provider_version_branch
          end
        end

        context "when there is a successful verification from before the first provider version with the specified tag was created" do
          before do
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("main")
              .create_verification(provider_version: "20", branch: "dev", success: true)
              .add_day
              .create_verification(provider_version: "21", branch: "feat-new-branch", number: 2, success: false)
          end

          let(:provider_version_branch) { "feat-new-branch" }

          it { is_expected.to be_empty }
        end

        context "when there is a successful verification from after the first provider version with the specified tag was created" do
          before do
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("main")
              .create_verification(provider_version: "21", branch: "feat-new-branch", number: 2, success: false)
              .add_day
              .create_verification(provider_version: "20", branch: "dev", success: true)
          end

          let(:provider_version_branch) { "feat-new-branch" }

          it "is included" do
            expect(subject.first.provider_branch).to eq provider_version_branch
          end
        end
      end
    end
  end
end
