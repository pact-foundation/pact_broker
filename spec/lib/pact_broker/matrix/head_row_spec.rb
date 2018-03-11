require 'pact_broker/matrix/head_row'

module PactBroker
  module Matrix
    describe HeadRow do
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
