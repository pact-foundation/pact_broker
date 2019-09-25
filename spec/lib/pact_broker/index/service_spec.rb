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
      let(:rows) { subject.find_index_items(options) }

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
              .use_provider_version("2.1.0")
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

        context "when the verification is the latest for a given tag" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_verification(provider_version: "1.0.0", tag_names: ['dev', 'prod'])
              .create_verification(provider_version: "2.0.0", number: 2, tag_names: ['dev'])
          end

          let(:rows) { subject.find_index_items(options) }
          let(:options) { { tags: true } }

          it "includes the names of the tags for which the verification is the latest of that tag" do
            expect(rows.first.provider_version_number).to eq "2.0.0"
            expect(rows.first.latest_verification_latest_tags.collect(&:name)).to eq ['dev']
          end
        end

        context "when there are multiple verifications for the latest consumer version" do

          context "with no tags" do
            before do
              td.create_pact_with_hierarchy("Foo", "1", "Bar")
                .create_verification(provider_version: "1.0.0")
                .create_verification(provider_version: "2.0.0", number: 2)
            end

            let(:options) { {} }

            it "only returns the row for the latest provider version" do
              expect(rows.count).to eq 1
            end
          end

          context "with tags=true" do
            before do
              td.create_pact_with_hierarchy("Foo", "1", "Bar")
                .create_consumer_version("2")
                .create_consumer_version_tag("prod")
                .create_consumer_version_tag("master")
                .create_pact
                .revise_pact
                .create_verification(provider_version: "1.0.0")
                .create_verification(provider_version: "2.0.0", number: 2)
            end

            let(:options) { {tags: true} }

            it "only returns the row for the latest provider version" do
              expect(rows.size).to eq 1
              expect(rows.first.tag_names.sort).to eq ["master","prod"]
              expect(rows.first.provider_version_number).to eq "2.0.0"
            end
          end

          context "with tags=true" do
            before do
              td.create_pact_with_hierarchy("Foo", "1.0.0", "Bar")
                .create_verification(provider_version: "4.5.6")
                .create_consumer_version("2.0.0")
                .create_consumer_version_tag("dev")
                .create_pact
                .revise_pact
                .create_consumer_version("2.1.0")
                .create_consumer_version_tag("prod")
                .create_pact
                .revise_pact
                .create_verification(provider_version: "4.5.6", number: 1)
                .create_verification(provider_version: "4.5.7", number: 2)
                .create_verification(provider_version: "4.5.8", number: 3)
                .create_verification(provider_version: "4.5.9", number: 4)
                .create_provider("Wiffle")
                .create_pact
            end

            let(:options) { {tags: true} }

            it "returns a row for each of the head pacts" do
              expect(rows.size).to eq 3

              expect(rows[0].latest?).to be true
              expect(rows[0].provider_name).to eq "Bar"
              expect(rows[0].tag_names).to eq ["prod"]
              expect(rows[0].provider_version_number).to eq "4.5.9"

              expect(rows[2].latest?).to be false
              expect(rows[2].provider_name).to eq "Bar"
              expect(rows[2].tag_names).to eq ["dev"]

              expect(rows[1].latest?).to be true
              expect(rows[1].provider_name).to eq "Wiffle"
            end
          end
        end

        context "when a pact with a tag has been verified, and then a new changed version has been published with the same tag" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_consumer_version_tag("feat-x")
              .comment("latest verification for feat-x tag")
              .create_verification(provider_version: "1")
              .comment("latest feat-x version")
              .create_consumer_version("2")
              .create_consumer_version_tag("feat-x")
              .comment("latest overall version")
              .create_consumer_version("3")
              .create_pact
              .comment("latest overall verification")
              .create_verification(provider_version: "2")

          end

          let(:options) { { tags: true } }

          it "returns the latest feat-x verification for the latest feat-x pact" do
            expect(rows.last.tag_names).to eq ["feat-x"]
            expect(rows.last.provider_version_number).to eq "1"
          end
        end

        context "when a pact with two tags has been verified, and then a new changed version has been published with two tags" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_consumer_version_tag("feat-x")
              .create_verification(provider_version: "1", comment: "latest feat-x verif")
              .create_consumer_version("2")
              .create_consumer_version_tag("feat-y")
              .create_pact
              .create_verification(provider_version: "2", comment: "latest feat-y verif")
              .create_consumer_version("3")
              .create_consumer_version_tag("feat-x")
              .create_consumer_version_tag("feat-y")
              .create_pact
              .create_consumer_version("4")
              .create_pact
          end

          let(:options) { { tags: true } }

          context "with tags=true" do
            it "returns the tags for the pacts" do
              expect(rows.last.tag_names.sort).to eq ["feat-x", "feat-y"]
            end
          end

          context "with tags=false" do
            let(:options) { { tags: false } }

            it "does not return the tags for the pacts" do
              expect(rows.last.tag_names.sort).to eq []
            end
          end

          context "with dashboard=true" do
            let(:options) { { dashboard: true } }

            it "returns the latest verification as nil as the pact version itself has not been verified" do
              expect(rows.last.provider_version_number).to be nil
            end
          end

          context "with dashboard=false" do
            let(:options) { { } }

            it "returns the latest of the feat-x and feat-y verifications because we are summarising the entire integration (backwards compat for OSS index)" do
              expect(rows.last.consumer_version_number).to eq "4"
              expect(rows.last.provider_version_number).to eq "2"
            end
          end
        end
      end
    end
  end
end
