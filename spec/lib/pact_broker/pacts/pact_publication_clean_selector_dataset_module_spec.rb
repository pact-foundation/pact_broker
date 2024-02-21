require "pact_broker/db/clean/selector"

module PactBroker
  module Pacts
    describe PactPublicationCleanSelectorDatasetModule do
      subject { PactPublication.latest_by_consumer_tag_for_clean_selector(selector).all_allowing_lazy_load.sort_by{ | pp | [pp.consumer_name, pp.consumer_version_number]} }

      context "for latest for a specified tag" do
        before do
          td.create_pact_with_hierarchy("Foo", "1", "Bar")
            .create_consumer_version_tag("dev")
            .create_pact_with_hierarchy("Foo", "2", "Bar")
            .create_consumer_version_tag("dev")
            .create_pact_with_hierarchy("Foo", "3", "Bar")
            .create_consumer_version_tag("prod")
        end

        let(:selector) { PactBroker::DB::Clean::Selector.new(tag: "dev", latest: true) }

        it "returns matching rows" do
          expect(subject.count).to eq 1
          expect(subject.first.consumer_version_number).to eq "2"
        end
      end

      context "for latest for a specified tag and consumer" do
        before do
          td.create_pact_with_hierarchy("Foo", "1", "Bar")
            .create_consumer_version_tag("dev")
            .create_pact_with_hierarchy("Foo", "2", "Bar")
            .create_consumer_version_tag("dev")
            .create_pact_with_hierarchy("Foo2", "3", "Bar")
            .create_consumer_version_tag("dev")
        end

        let(:selector) { PactBroker::DB::Clean::Selector.new(tag: "dev", latest: true, pacticipant_name: "Foo") }

        it "returns matching rows" do
          expect(subject.count).to eq 1
          expect(subject.first.consumer_version_number).to eq "2"
        end
      end

      context "for all for a specified tag" do
        before do
          td.create_pact_with_hierarchy("Foo", "1", "Bar")
            .create_consumer_version_tag("dev")
            .create_pact_with_hierarchy("Foo", "2", "Bar")
            .create_consumer_version_tag("dev")
            .create_pact_with_hierarchy("Foo", "3", "Bar")
            .create_consumer_version_tag("prod")
        end

        let(:selector) { PactBroker::DB::Clean::Selector.new(tag: "dev") }

        it "returns matching rows (which are only the latest)" do
          expect(subject.count).to eq 1
          expect(subject.first.consumer_version_number).to eq "2"
        end
      end

      context "for latest for any tag" do
        before do
          td.create_pact_with_hierarchy("Foo", "1", "Bar")
            .create_consumer_version_tag("dev")
            .create_pact_with_hierarchy("Foo", "2", "Bar")
            .create_consumer_version_tag("dev")
            .create_pact_with_hierarchy("Foo", "3", "Bar")
            .create_consumer_version_tag("prod")
        end

        let(:selector) { PactBroker::DB::Clean::Selector.new(tag: true, latest: true) }

        it "returns matching rows" do
          expect(subject.count).to eq 2
          expect(subject.first.consumer_version_number).to eq "2"
        end
      end

      context "for latest for any tag with a max age" do
        before do
          td.subtract_days(7)
            .create_pact_with_hierarchy("Foo", "1", "Bar")
            .create_consumer_version_tag("prod")
            .add_days(4)
            .create_pact_with_hierarchy("Foo", "2", "Bar")
            .create_consumer_version_tag("dev")
        end

        let(:selector) { PactBroker::DB::Clean::Selector.new(tag: true, latest: true, max_age: 5) }

        it "returns matching rows" do
          expect(subject.count).to eq 1
          expect(subject.first.consumer_version_number).to eq "2"
        end
      end
    end
  end
end
