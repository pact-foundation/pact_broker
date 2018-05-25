require 'pact_broker/matrix/head_row'

module PactBroker
  module Matrix
    describe HeadRow do
      let(:td) { TestDataBuilder.new }

      describe "latest_verification_for_consumer_version_tag" do
        context "when the pact with a given tag has been verified" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_consumer_version_tag("prod")
              .create_verification(provider_version: "10")
              .create_consumer_version("2", comment: "latest prod version for Foo")
              .create_consumer_version_tag("prod")
              .create_pact
              .create_verification(provider_version: "11")
              .create_verification(provider_version: "12", number: 2)
              .create_consumer("Wiffle")
              .create_consumer_version("30", comment: "latest prod version for Wiffle")
              .create_consumer_version_tag("prod")
              .create_pact
              .create_verification(provider_version: "12")
              .create_provider("Meep")
              .create_pact
              .create_verification(provider_version: "40")
          end

          subject { HeadRow.eager(:consumer_version_tags).eager(:latest_verification_for_consumer_version_tag).order(:pact_publication_id, :verification_id).exclude(consumer_version_tag_name: nil).all }

          it "returns its most recent verification" do
            cols = [:consumer_name, :consumer_version_number, :consumer_version_tag_name, :provider_name, :provider_version_number]
            rows = subject.collect{ | row | cols.collect{ | col | row[col]} }

            expect(subject.size).to eq 3
            expect(rows).to include ["Foo", "2", "prod", "Bar", "12"]
            expect(rows).to include ["Wiffle", "30", "prod", "Bar", "12"]
            expect(rows).to include ["Wiffle", "30", "prod", "Meep", "40"]
          end
        end

        context "when the most recent pact with a given tag has not been verified, but a previous version with the same tag has" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_consumer_version_tag("prod")
              .create_verification(provider_version: "10")
              .create_verification(provider_version: "11", number: 2, comment: "this is the latest verification for a pact with cv tag prod")
              .create_consumer_version("2")
              .create_consumer_version_tag("prod")
              .create_pact
          end

          subject { HeadRow.eager(:consumer_version_tags).eager(:latest_verification_for_consumer_version_tag).order(:pact_publication_id).all }

          it "returns the most recent verification for the previous version with the same tag" do
            expect(subject.last.verification_id).to be nil # this pact version has not been verified directly
            expect(subject.last.latest_verification_for_consumer_version_tag.provider_version.number).to eq "11"
          end
        end
      end
      describe "refresh", migration: true do
        before do
          PactBroker::Database.migrate
        end

        let(:td) { TestDataBuilder.new(auto_refresh_matrix: false) }

        before do
          td.create_pact_with_hierarchy("Foo", "1", "Bar")
        end

        context "with a consumer pacticipant_id and a consumer tag_name" do
          before do
            td.create_consumer_version_tag("prod")
            Row.refresh(ids)
          end
          let(:ids) { { pacticipant_id: td.consumer.id, tag_name: "prod"} }

          subject { HeadRow.refresh(ids) }

          it "refreshes the data for the consumer and consumer tag in the head matrix" do
            subject
            expect(HeadRow.all.collect(&:values)).to contain_hash(provider_name: "Bar", consumer_name: "Foo", consumer_version_tag_name: "prod")
          end
        end

        context "with a provider pacticipant_id and a provider tag_name" do
          before do
            td.create_verification(provider_version: "2")
              .use_provider_version("2")
              .create_provider_version_tag("prod")
            Row.refresh(ids)
          end

          let(:ids) { { pacticipant_id: td.consumer.id, tag_name: "prod" } }

          subject { HeadRow.refresh(ids) }

          it "does not update the head matrix as the head matrix only contains consumer tags" do
            subject
            expect(HeadRow.count).to eq 0
          end
        end
      end
    end
  end
end
