require 'pact_broker/pacts/repository'

module PactBroker
  module Pacts
    describe Repository do
      describe "find_wip_pact_versions_for_provider" do
        let(:provider_tags) { %w[dev] }
        let(:options) { { include_wip_pacts_since: include_wip_pacts_since } }
        let(:include_wip_pacts_since) { (Date.today - 1).to_datetime }

        subject { Repository.new.find_wip_pact_versions_for_provider("bar", provider_tags, options) }

        context "when there are no tags" do
          let(:provider_tags) { [] }

          it "returns an empty list" do
            expect(subject).to eq []
          end
        end

        context "when there are multiple wip pacts" do
          before do
            td.create_provider("bar")
              .create_provider_version("333")
              .create_provider_version_tag("dev")
              .add_day
              .create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("feat-1")
              .add_day
              .create_pact_with_hierarchy("meep", "2", "bar")
              .create_consumer_version_tag("feat-2")
              .add_day
              .create_pact_with_hierarchy("foo", "2", "bar")
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

            expect(subject[2].consumer_name).to eq "meep"
            expect(subject[2].consumer_version_number).to eq "2"

            expect(subject[3].consumer_name).to eq "meep"
            expect(subject[3].consumer_version_number).to eq "1"
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

        context "when the first provider tag with a given name was created after the head pact was created" do
          before do
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("feat-x")
              .add_day
              .create_provider_version("5")
              .create_provider_version_tag(provider_tags.first)
          end

          it "doesn't return any pacts" do
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

          it "doesn't return any pacts" do
            expect(subject.size).to be 0
          end
        end


        context "when a pact was published between the first creation date of two provider tags" do
          let(:provider_tags) { %w[dev feat-1] }

          before do
            td.create_provider("bar")
              .create_provider_version("4")
              .create_provider_version_tag(provider_tags.first)
              .add_day
              .create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("feat-x")
              .add_day
              .create_provider_version("5")
              .create_provider_version_tag(provider_tags.last)
          end

          it "is wip for the first tag but not the second" do
            expect(subject.first.pending_provider_tags).to eq [provider_tags.first]
          end
        end
      end
    end
  end
end
