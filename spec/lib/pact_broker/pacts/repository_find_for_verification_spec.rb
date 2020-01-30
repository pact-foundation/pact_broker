require 'pact_broker/pacts/repository'

module PactBroker
  module Pacts
    describe Repository do
      let(:td) { TestDataBuilder.new }

      describe "#find_for_verification" do

        def find_by_consumer_version_number(consumer_version_number)
          subject.find{ |pact| pact.consumer_version_number == consumer_version_number }
        end

        def find_by_consumer_name_and_consumer_version_number(consumer_name, consumer_version_number)
          subject.find{ |pact| pact.consumer_name == consumer_name && pact.consumer_version_number == consumer_version_number }
        end

        before do
          td.create_pact_with_hierarchy("Foo", "foo-latest-prod-version", "Bar")
            .create_consumer_version_tag("prod")
            .create_consumer_version("not-latest-dev-version", tag_names: ["dev"])
            .comment("next pact not selected")
            .create_pact
            .create_consumer_version("foo-latest-dev-version", tag_names: ["dev"])
            .create_pact
            .create_consumer("Baz")
            .create_consumer_version("baz-latest-dev-version", tag_names: ["dev"])
            .create_pact
        end

        subject { Repository.new.find_for_verification("Bar", consumer_version_selectors) }

        context "when there are no selectors" do
          let(:consumer_version_selectors) { [] }

          it "returns the latest pact for each consumer" do
            expect(subject.size).to eq 2
            expect(find_by_consumer_name_and_consumer_version_number("Foo", "foo-latest-dev-version")).to_not be nil
            expect(find_by_consumer_name_and_consumer_version_number("Baz", "baz-latest-dev-version")).to_not be nil
          end
        end

        context "when consumer tag names are specified" do
          let(:pact_selector_1) { double('selector', tag: 'dev', latest: true) }
          let(:pact_selector_2) { double('selector', tag: 'prod', latest: true) }
          let(:consumer_version_selectors) do
            [pact_selector_1, pact_selector_2]
          end

          it "returns the latest pact with the specified tags for each consumer" do
            expect(find_by_consumer_version_number("foo-latest-prod-version")).to_not be nil
            expect(find_by_consumer_version_number("foo-latest-dev-version")).to_not be nil
            expect(find_by_consumer_version_number("baz-latest-dev-version")).to_not be nil
            expect(subject.size).to eq 3
          end

          it "sets the latest_consumer_version_tag_names" do
            expect(find_by_consumer_version_number("foo-latest-prod-version").tag).to eq 'prod'
          end

          context "when all versions with a given tag are requested" do
            before do
              td.create_pact_with_hierarchy("Foo2", "prod-version-1", "Bar2")
                .create_consumer_version_tag("prod")
                .create_consumer_version("not-prod-version", tag_names: %w[master])
                .create_pact
                .create_consumer_version("prod-version-2", tag_names: %w[prod])
                .create_pact
            end

            let(:consumer_version_selectors) { [pact_selector_1] }
            let(:pact_selector_1) { double('selector', tag: 'prod', latest: nil) }

            subject { Repository.new.find_for_verification("Bar2", consumer_version_selectors) }

            it "returns all the versions with the specified tag" do
              expect(subject.size).to be 2
              expect(find_by_consumer_version_number("prod-version-1")).to_not be nil
              expect(find_by_consumer_version_number("prod-version-2")).to_not be nil
            end

            it "dedupes them to ensure that each pact version is only verified once" do
              td.create_consumer_version("prod-version-3", tag_names: %w[prod])
                .republish_same_pact
              expect(subject.size).to be 2
              expect(subject.collect(&:consumer_version_number)).to eq %w[prod-version-1 prod-version-3]
            end
          end
        end

        context "when no selectors are specified" do
          let(:consumer_version_selectors) { [] }

          it "returns the latest pact for each provider" do
            expect(find_by_consumer_version_number("foo-latest-dev-version")).to_not be nil
            expect(find_by_consumer_version_number("baz-latest-dev-version")).to_not be nil
            expect(subject.size).to eq 2
          end

          it "does not set the tag name" do
            expect(find_by_consumer_version_number("foo-latest-dev-version").tag).to be nil
            expect(find_by_consumer_version_number("foo-latest-dev-version").overall_latest?).to be true
          end
        end
      end
    end
  end
end
