require 'pact_broker/matrix/row'

module PactBroker
  module Matrix
    describe Row do
      let(:td) { TestDataBuilder.new }

      describe "latest_verification_for_consumer_version_tag" do
        context "when the pact with a given tag has been verified" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_consumer_version_tag("prod")
              .create_verification(provider_version: "10")
              .create_consumer_version("2")
              .create_consumer_version_tag("prod")
              .create_pact
              .create_verification(provider_version: "11", number: 1)
              .create_verification(provider_version: "12", number: 2)
          end

          subject { Row.eager(:consumer_version_tags).eager(:latest_verification_for_consumer_version_tag).order(:pact_publication_id, :verification_id).all }

          it "returns its most recent verification" do
            expect(subject.last.provider_version_number).to eq "12"
            expect(subject.last.latest_verification_for_consumer_version_tag.provider_version.number).to eq "12"
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

          subject { Row.eager(:consumer_version_tags).eager(:latest_verification_for_consumer_version_tag).order(:pact_publication_id).all }

          it "returns the most recent verification for the previous version with the same tag" do
            expect(subject.last.verification_id).to be nil # this pact version has not been verified directly
            expect(subject.last.latest_verification_for_consumer_version_tag.provider_version.number).to eq "11"
          end
        end
      end

      describe "refresh", migration: true do
        let(:td) { TestDataBuilder.new(auto_refresh_matrix: false) }

        before do
          PactBroker::Database.migrate
          td.create_pact_with_hierarchy("Foo", "1", "Bar")
        end

        context "with only a consumer_id" do
          subject { Row.refresh(consumer_id: td.consumer.id) }

          it "refreshes the data for the consumer" do
            subject
            expect(Row.all.collect(&:values)).to contain_hash(provider_name: "Bar", consumer_name: "Foo")
          end
        end

        context "with only a provider_id" do
          subject { Row.refresh(provider_id: td.provider.id) }

          it "refreshes the data for the provider" do
            subject
            expect(Row.all.collect(&:values)).to contain_hash(provider_name: "Bar", consumer_name: "Foo")
          end
        end

        context "with both consumer_id and provider_id" do
          subject { Row.refresh(provider_id: td.provider.id, consumer_id: td.consumer.id) }

          it "refreshes the data for the consumer and provider" do
            subject
            expect(Row.all.collect(&:values)).to contain_hash(provider_name: "Bar", consumer_name: "Foo")
          end
        end

        context "when there was existing data" do
          it "deletes the existing data before inserting the new data" do
            Row.refresh(provider_id: td.provider.id, consumer_id: td.consumer.id)
            expect(Row.count).to eq 1
            td.create_consumer_version("2")
              .create_pact
            Row.refresh(provider_id: td.provider.id, consumer_id: td.consumer.id)
            expect(Row.count).to eq 2
          end
        end

        context "with a pacticipant_id" do
          subject { Row.refresh(pacticipant_id: td.provider.id) }

          it "refreshes the data for both consumer and provider roles" do
            subject
            expect(Row.all.collect(&:values)).to contain_hash(provider_name: "Bar", consumer_name: "Foo")
          end
        end
      end

      describe "<=>" do
        let(:row_1) do
          Row.new(
            consumer_name: 'A',
            consumer_version_order: 1,
            pact_revision_number: 1,
            provider_name: 'B',
            provider_version_order: 1,
            verification_id: 1
          )
        end
        let(:row_2) do
          Row.new(
            consumer_name: 'A',
            consumer_version_order: 1,
            pact_revision_number: 1,
            provider_name: 'B',
            provider_version_order: 1,
            verification_id: 2
          )
        end

        it "sorts" do
          expect([row_1, row_2].sort).to eq [row_2, row_1]
        end

        context "with a nil column" do
          let(:row_2) do
            Row.new(
              consumer_name: 'A',
              consumer_version_order: 1,
              pact_revision_number: 1,
              provider_name: 'B',
              provider_version_order: nil,
              verification_id: nil
            )
          end

          it "sorts the rows first" do
            expect([row_1, row_2].sort).to eq [row_2, row_1]
          end
        end
      end
    end
  end
end
