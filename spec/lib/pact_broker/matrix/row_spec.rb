require 'pact_broker/matrix/row'

module PactBroker
  module Matrix
    describe Row do
      let(:td) { TestDataBuilder.new }

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
