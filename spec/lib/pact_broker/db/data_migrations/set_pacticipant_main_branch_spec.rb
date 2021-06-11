require "pact_broker/db/data_migrations/set_pacticipant_main_branch"

module PactBroker
  module DB
    module DataMigrations
      describe SetPacticipantMainBranch, data_migration: true  do
        describe ".call" do
          before(:all) do
            PactBroker::Database.migrate(20210529)
          end

          let(:now) { DateTime.new(2018, 2, 2) }
          let!(:pacticipant_1) { create(:pacticipants, { name: "P1", created_at: now, updated_at: now }) }
          let!(:pacticipant_2) { create(:pacticipants, { name: "P2", created_at: now, updated_at: now }) }

          def create_version_with_tag(version_number, order, tag_name, pacticipant_id)
            version = create(:versions, { number: version_number, order: order, pacticipant_id: pacticipant_id, created_at: now, updated_at: now })
            create(:tags, { name: tag_name, pacticipant_id: pacticipant_id, version_id: version[:id], created_at: now, updated_at: now }, nil)
          end

          before do
            create_version_with_tag("1", 1, "main", pacticipant_1[:id])
            create_version_with_tag("2", 2, "main", pacticipant_1[:id])
            create_version_with_tag("3", 3, "develop", pacticipant_1[:id])
            create_version_with_tag("4", 4, "feat/x", pacticipant_1[:id])

            create_version_with_tag("5", 5, "foo", pacticipant_2[:id])
          end

          subject { SetPacticipantMainBranch.call(database) }

          it "sets the main branch where it can" do
            subject
            expect(database[:pacticipants].where(id: pacticipant_1[:id]).single_record[:main_branch]).to eq "main"
            expect(database[:pacticipants].where(id: pacticipant_2[:id]).single_record[:main_branch]).to eq nil
          end
        end
      end
    end
  end
end
