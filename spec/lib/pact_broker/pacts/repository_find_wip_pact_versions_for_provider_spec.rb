require 'pact_broker/pacts/repository'

module PactBroker
  module Pacts
    describe Repository do
      let(:td) { TestDataBuilder.new }

      describe "find_pending_pact_versions_for_provider" do
        subject { Repository.new.find_pending_pact_versions_for_provider("bar") }

        context "when the latest pact for a tag has been successfully verified" do
          before do
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .comment("above not included because it's not the latest prod")
              .create_consumer_version("2")
              .create_consumer_version_tag("prod")
              .create_pact
              .create_verification(provider_version: "3", comment: "not included because already verified")
          end

          it "is not included" do
            expect(subject.size).to be 0
          end
        end

        context "when the latest pact without a tag has failed verification" do
          before do
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .create_verification(provider_version: "3", success: false)
          end

          it "is included" do
            expect(subject.size).to be 1
          end
        end

        context "when the latest pact without a tag has not been verified" do
          before do
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version("2")
              .create_pact
          end

          it "is included" do
            expect(subject.first.consumer_version_number).to eq "2"
            expect(subject.size).to be 1
          end
        end

        context "when the latest pact for a tag has failed verification" do
          before do
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("prod")
              .create_verification(provider_version: "3", success: true)
              .create_consumer_version("2", tag_names: ["prod"])
              .create_pact
              .create_verification(provider_version: "5", success: false)
          end

          it "is included" do
            expect(subject.first.consumer_version_number).to eq "2"
            expect(subject.size).to be 1
          end
        end

        context "when the latest pact for a tag has not been verified" do
          before do
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("prod")
              .create_verification(provider_version: "5")
              .create_consumer_version("2", tag_names: ["prod"])
              .create_pact
          end

          it "is included" do
            expect(subject.first.consumer_version_number).to eq "2"
            expect(subject.size).to be 1
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
      end
    end
  end
end
