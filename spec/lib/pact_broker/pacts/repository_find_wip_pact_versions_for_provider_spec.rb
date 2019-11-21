require 'pact_broker/pacts/repository'

module PactBroker
  module Pacts
    describe Repository do
      let(:td) { TestDataBuilder.new }

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

        context "when the latest pact for a tag has been successfully verified by one of the given provider tags, but not the other" do
          before do
            td.create_pact_with_hierarchy("foo", "1", "bar")
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
            td.create_pact_with_hierarchy("foo", "1", "bar")
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
            td.create_pact_with_hierarchy("foo", "1", "bar")
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
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("dev")
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
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("prod")
          end

          let(:include_wip_pacts_since) { (Date.today + 3).to_datetime }

          it "is not included" do
            expect(subject.size).to be 0
          end
        end
      end
    end
  end
end
