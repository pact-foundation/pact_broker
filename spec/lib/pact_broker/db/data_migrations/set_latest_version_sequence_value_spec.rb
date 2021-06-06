require "pact_broker/db/data_migrations/set_latest_version_sequence_value"

module PactBroker
  module DB
    module DataMigrations
      describe SetLatestVersionSequenceValue, data_migration: true do
        include MigrationHelpers

        describe ".call" do
          before(:all) do
            PactBroker::Database.migrate(20190509)
          end

          let(:now) { DateTime.new(2018, 2, 2) }

          subject { SetLatestVersionSequenceValue.call(database) }

          context "when there is no sequence value set" do
            context "when there are no versions" do
              it "initializes the sequence value - this is required at start up each time in case someone has changed the ordering configuration (date vs semantic)" do
                subject
                expect(database[:version_sequence_number].first[:value]).to eq 100
              end
            end

            context "when there are pre-existing versions" do
              let!(:consumer) { create(:pacticipants, {name: "Consumer", created_at: now, updated_at: now}) }
              let!(:consumer_version) { create(:versions, {number: "1.2.3", order: 1, pacticipant_id: consumer[:id], created_at: now, updated_at: now}) }
              let!(:consumer_version) { create(:versions, {number: "1.2.5", order: 3, pacticipant_id: consumer[:id], created_at: now, updated_at: now}) }

              it "initializes the sequence value to the max version order with a margin of error" do
                subject
                expect(database[:version_sequence_number].first[:value]).to eq 103
              end
            end
          end

          context "when a value already exists and it is already higher than the max_order" do
            before do
              database[:version_sequence_number].insert(value: 5)
            end

            it "does not update the value" do
              subject
              expect(database[:version_sequence_number].first[:value]).to eq 5
              expect(database[:version_sequence_number].count).to eq 1
            end
          end

          context "when a value already exists and it not higher than the max_order" do
            before do
              database[:version_sequence_number].insert(value: 3)
            end

            let!(:consumer) { create(:pacticipants, {name: "Consumer", created_at: now, updated_at: now}) }
            let!(:consumer_version) { create(:versions, {number: "1.2.3", order: 1, pacticipant_id: consumer[:id], created_at: now, updated_at: now}) }
            let!(:consumer_version) { create(:versions, {number: "1.2.5", order: 3, pacticipant_id: consumer[:id], created_at: now, updated_at: now}) }

            it "updates the value" do
              subject
              expect(database[:version_sequence_number].first[:value]).to eq 103
            end
          end
        end
      end
    end
  end
end
