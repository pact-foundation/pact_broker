require "pact_broker/pacts/repository"

module PactBroker
  module Pacts
    describe Repository do
      describe "find_wip_pact_versions_for_provider" do
        let(:provider_tags) { %w[dev] }
        let(:provider_version_branch) { nil }
        let(:options) { { include_wip_pacts_since: include_wip_pacts_since } }
        let(:include_wip_pacts_since) { (Date.today - 1).to_datetime }

        subject { Repository.new.find_wip_pact_versions_for_provider("bar", provider_version_branch, provider_tags, [], options) }

        context "when there are no tags" do
          let(:provider_tags) { [] }

          it "returns an empty list" do
            expect(subject).to eq []
          end
        end

        context "when there are multiple wip pacts" do
          before do
            td.create_provider("bar")
              .create_provider_version("333", tag_names: provider_tags)
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

          let(:provider_tags) { %w[dev] }

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

        context "when there are multiple wip pacts with the same content" do
          before do
            td.create_provider("bar")
              .create_provider_version("333")
              .create_provider_version_tag("dev")
              .add_day
              .create_pact_with_hierarchy("foo", "1", "bar", json_content)
              .create_consumer_version_tag("feat-1")
              .add_day
              .create_pact_with_hierarchy("foo", "2", "bar", json_content)
              .create_consumer_version_tag("feat-2")
          end

          let(:json_content) { { "interactions" => ["foo"] }.to_json }
          let(:provider_tags) { %w[dev] }

          it "de-duplicates them" do
            expect(subject.size).to eq 1
          end

          it "merges the selectors" do
            expect(subject.first.selectors.size).to eq 2
            expect(subject.first.wip).to be true
          end
        end

        context "when the latest pact for a tag has been successfully verified by the given provider tag" do
          before do
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .comment("above not included because it's not the latest prod")
              .create_consumer_version("2")
              .create_consumer_version_tag("prod")
              .create_pact
              .create_verification(provider_version: "3", tag_names: %w[dev], comment: "not included because already verified")
          end

          let(:provider_tags) { %w[dev] }

          it "is not included" do
            expect(subject.size).to be 0
          end
        end

        context "when the latest pact for a tag has been successfully verified by the given provider tag but it was a WIP verification" do
          before do
            td.create_provider("bar")
              .create_provider_version("333")
              .create_provider_version_tag("dev")
              .add_day
              .create_pact_with_hierarchy("foo", "1", "bar")
              .comment("above not included because it's not the latest dev")
              .create_consumer_version("2")
              .create_consumer_version_tag("feat-1")
              .create_pact
              .create_verification(wip: true, success: true, provider_version: "3", tag_names: %w[dev])
          end

          let(:provider_tags) { %w[dev] }

          it "it is included" do
            expect(subject[0].consumer_name).to eq "foo"
            expect(subject[0].consumer_version_number).to eq "2"
          end
        end

        context "when the latest pact for a tag has been successfully verified by one of the given provider tags, but not the other" do
          before do
            td.create_provider("bar")
              .create_provider_version("44")
              .create_provider_version_tag("feat-1")
              .add_day
              .create_consumer("foo")
              .create_consumer_version("1")
              .create_pact
              .create_consumer_version_tag("prod")
              .create_verification(provider_version: "3", tag_names: %w[dev], comment: "not included because already verified")
          end

          let(:provider_tags) { %w[dev feat-1] }

          it "is included" do
            expect(subject.size).to be 1
          end

          it "sets the pending tags to the tag that has not yet been verified" do
            expect(subject.first.pending_provider_tags).to eq %w[feat-1]
          end
        end

        context "when the latest pact for a tag has failed verification from the specified provider version" do
          before do
            td.create_provider("bar")
              .create_provider_version("333")
              .create_provider_version_tag("dev")
              .add_day
              .create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("feat-1")
              .create_verification(provider_version: "3", success: false, tag_names: %[dev])
          end

          it "is included" do
            expect(subject.size).to be 1
          end

          it "sets the pending tags" do
            expect(subject.first.pending_provider_tags).to eq %w[dev]
          end
        end

        context "when there are no consumer tags" do
          before do
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .create_verification(provider_version: "3", success: false, tag_names: %[dev])
          end

          it "returns an empty list" do
            expect(subject).to eq []
          end
        end

        context "when the latest pact for a tag has successful and failed verifications" do
          before do
            td.create_provider("bar")
              .create_provider_version("333")
              .create_provider_version_tag("dev")
              .add_day
              .create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("dev")
              .create_verification(provider_version: "3", success: true, tag_names: %[dev])
              .create_verification(provider_version: "5", success: false, number: 2, tag_names: %[dev])
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
            expect(subject.first.pending_provider_tags).to eq %w[dev]
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
              .create_provider_version("333")
              .create_provider_version_tag("dev")
              .add_day
              .create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("prod")
          end

          let(:include_wip_pacts_since) { (Date.today + 3).to_datetime }

          it "is not included" do
            expect(subject.size).to be 0
          end
        end

        context "when the provider tag does not exist yet and there are no provider versions" do
          before do
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("feat-x")
          end

          it "is included" do
            expect(subject.size).to be 1
          end
        end

        context "when the provider tag does not exist yet but there are other provider versions" do
          before do
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("feat-x")
              .create_provider_version("1")
          end

          it "is included" do
            expect(subject.size).to be 1
          end
        end

        context "when a pact was already successfully verified by another branch before the first creation of one tag but not the other" do
          let(:provider_tags) { %w[dev feat-1] }

          before do
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("feat-x")
              .add_day
              .create_verification(provider_version: "1", success: false, number: 1, tag_names: %w[dev])
              .add_day
              .create_verification(provider_version: "2", success: true, number: 2, tag_names: %w[blah])
              .add_day
              .create_verification(provider_version: "3", success: false, number: 3, tag_names: %w[feat-1])
          end

          it "is wip for the first tag but not the second" do
            expect(subject.first.pending_provider_tags).to eq %w[dev]
          end
        end

        context "when a pact was already successfully verified by another branch before the first creation of one tag but not the other" do
          let(:provider_tags) { %w[dev feat-1] }

          before do
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("feat-x")
              .add_day
              .create_verification(provider_version: "1", success: true, number: 1, tag_names: %w[dev])
              .add_day
              .create_verification(provider_version: "3", success: false, number: 3, tag_names: %w[feat-1])
          end

          it "this should be WIP, as it hasn't been successfully verified by both dev AND feat-1 - need to update logic to exclude previous verifications from other specified tags. But two tags doesn't make sense anyway. Will leave it for now.", pending: true do
            expect(subject).to_not be_empty
          end
        end

        context "when the provider version tag specified does not exist yet and there are previous successful verifications from another branch" do
          before do
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("main")
              .create_verification(provider_version: "20", tag_names: ["dev"], success: true)
              .create_verification(provider_version: "21", number: 2)
          end

          let(:provider_tags) { %w[feat-new-branch] }

          it { is_expected.to be_empty }
        end

        context "when the provider version tag specified does not exist yet and there are previous failed verifications from another branch" do
          before do
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("main")
              .create_verification(provider_version: "20", tag_names: ["dev"], success: false)
              .create_verification(provider_version: "21", number: 2)
          end

          let(:provider_tags) { %w[feat-new-branch] }

          it "is included" do
            expect(subject.first.pending_provider_tags).to eq [provider_tags.first]
          end
        end

        context "when there is a successful verification from before the first provider version with the specified tag was created" do
          before do
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("main")
              .create_verification(provider_version: "20", tag_names: ["dev"], success: true)
              .add_day
              .create_verification(provider_version: "21", tag_names: ["feat-new-branch"], number: 2, success: false)
          end

          let(:provider_tags) { %w[feat-new-branch] }

          it { is_expected.to be_empty }
        end

        context "when there is a successful verification from after the first provider version with the specified tag was created" do
          before do
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("main")
              .create_verification(provider_version: "21", tag_names: ["feat-new-branch"], number: 2, success: false)
              .add_day
              .create_verification(provider_version: "20", tag_names: ["dev"], success: true)
          end

          let(:provider_tags) { %w[feat-new-branch] }

          it "is included" do
            expect(subject.first.pending_provider_tags).to eq [provider_tags.first]
          end
        end
      end
    end
  end
end
