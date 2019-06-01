require 'pact_broker/pacts/repository'

module PactBroker
  module Pacts
    describe Repository do
      let(:td) { TestDataBuilder.new }

      describe "#find_for_verification" do

        def find_by_consumer_version_number(consumer_version_number)
          subject.find{ |pact| pact.consumer_version_number == consumer_version_number }
        end

        before do
          td.create_pact_with_hierarchy("Foo", "bar-latest-prod", "Bar")
            .create_consumer_version_tag("prod")
            .create_consumer_version("not-latest-dev", tag_names: ["dev"])
            .comment("next pact not selected")
            .create_pact
            .create_consumer_version("bar-latest-dev", tag_names: ["dev"])
            .create_pact
            .create_consumer("Baz")
            .create_consumer_version("baz-latest-dev", tag_names: ["dev"])
            .create_pact
        end

        subject { Repository.new.find_for_verification("Bar", consumer_version_selectors) }

        context "when consumer tag names are specified" do
          let(:pact_selector_1) { double('selector', tag: 'dev', latest: true) }
          let(:pact_selector_2) { double('selector', tag: 'prod', latest: true) }
          let(:consumer_version_selectors) do
            [pact_selector_1, pact_selector_2]
          end

          it "returns the latest pact with the specified tags for each consumer" do
            expect(find_by_consumer_version_number("bar-latest-prod")).to_not be nil
            expect(find_by_consumer_version_number("bar-latest-dev")).to_not be nil
            expect(find_by_consumer_version_number("baz-latest-dev")).to_not be nil
            expect(subject.size).to eq 3
          end

          it "sets the latest_consumer_version_tag_names" do
            expect(find_by_consumer_version_number("bar-latest-prod").head_tag).to eq 'prod'
          end
        end

        context "when no selectors are specified" do
          let(:consumer_version_selectors) { [] }

          it "returns the latest pact for each provider" do
            expect(find_by_consumer_version_number("bar-latest-dev")).to_not be nil
            expect(find_by_consumer_version_number("baz-latest-dev")).to_not be nil
            expect(subject.size).to eq 2
          end

          it "does not set the tag name" do
            expect(find_by_consumer_version_number("bar-latest-dev").head_tag).to be nil
            expect(find_by_consumer_version_number("bar-latest-dev").overall_latest?).to be true
          end
        end
      end
    end
  end
end
