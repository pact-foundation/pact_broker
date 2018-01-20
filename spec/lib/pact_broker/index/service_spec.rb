require 'spec_helper'
require 'pact_broker/index/service'
require 'pact_broker/domain/tag'
require 'pact_broker/domain/pact'

module PactBroker

  module Index
    describe Service do
      let(:td) { TestDataBuilder.new }
      let(:tags) { ['prod', 'production'] }
      let(:options) { { tags: tags } }

      subject{ Service }

      describe "find_relationships integration test" do
        context "when a prod pact exists and is not the latest version" do
          before do
            td.create_pact_with_hierarchy("Foo", "1.2.3", "Bar")
              .create_consumer_version_tag("prod")
              .create_consumer_version_tag("ignored")
              .create_verification(provider_version: "2.0.0")
              .create_consumer_version("1.2.4")
              .create_consumer_version_tag("also-ignored")
              .create_pact
              .create_verification(provider_version: "2.1.0")
          end

          let(:rows) { subject.find_index_items(options) }

          it "returns both rows" do
            expect(rows.count).to eq 2
          end

          context "when the tags are not specified" do
            let(:options) { {} }

            it "only returns the latest row" do
              expect(rows.count).to eq 1
            end
          end

          it "returns the latest row first" do
            expect(rows.first.consumer_version_number).to eq "1.2.4"
            expect(rows.last.consumer_version_number).to eq "1.2.3"
          end

          it "designates the first row as the latest row, and the second as not latest" do
            expect(rows.first.latest?).to be true
            expect(rows.last.latest?).to be false
          end

          it "doesn't return any tag names for the latest row" do
            expect(rows.first.tag_names).to eq []
          end

          it "includes the prod tag name for the prod row" do
            expect(rows.last.tag_names).to eq ['prod']
          end

          it "includes the latest overall verification for the latest pact" do
            expect(rows.first.latest_verification.provider_version_number).to eq '2.1.0'
          end

          it "includes the latest prod verification for the prod pact" do
            expect(rows.last.latest_verification.provider_version_number).to eq '2.0.0'
          end
        end

        context "when the prod version is the latest version" do
          before do
            td.create_pact_with_hierarchy("Foo", "1.2.3", "Bar")
              .create_consumer_version_tag("prod")
              .create_consumer_version_tag("ignored")
              .create_verification(provider_version: "2.0.0")
          end

          let(:rows) { subject.find_index_items(options) }

          it "returns one row" do
            expect(rows.count).to eq 1
          end

          it "designates the row as the latest row" do
            expect(rows.first.latest?).to be true
          end

          it "includes the prod tag name for the row" do
            expect(rows.first.tag_names).to eq ['prod']
          end

          it "includes the latest overall verification for the latest pact" do
            expect(rows.first.latest_verification.provider_version_number).to eq '2.0.0'
          end
        end
      end
    end
  end
end
