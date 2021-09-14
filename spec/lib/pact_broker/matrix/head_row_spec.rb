require "pact_broker/matrix/head_row"

module PactBroker
  module Matrix
    describe HeadRow do
      let(:td) { TestDataBuilder.new }

      describe "webhooks" do
        let(:td) { TestDataBuilder.new }

        before do
          td.create_consumer("Foo")
            .create_provider("Bar")
            .create_consumer_version
            .create_pact
            .create_global_webhook(description: 'global')
            .create_consumer_webhook(description: 'consumer')
            .create_provider_webhook(description: 'provider')
            .create_provider("Wiffle")
            .create_provider_webhook(description: 'wiffle')
        end

        let(:row) { HeadRow.where(consumer_name: "Foo", provider_name: "Bar").single_record }

        it "returns all the webhooks" do
          rows = HeadRow.eager(:webhooks).all
          expect(rows.first.webhooks).to contain_exactly(
            have_attributes(description: 'global'),
            have_attributes(description: 'provider'),
            have_attributes(description: 'consumer')
          )
        end
      end

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

          subject { HeadRow.where(verification_id: nil, consumer_version_tag_name: "prod").eager(:consumer_version_tags).eager(:latest_verification_for_consumer_version_tag).order(:pact_publication_id).all }

          it "returns the most recent verification for the previous version with the same tag" do
            expect(subject.last.latest_verification_for_consumer_version_tag.provider_version.number).to eq "11"
          end
        end
      end
    end
  end
end
