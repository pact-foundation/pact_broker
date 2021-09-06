require "pact_broker/db/data_migrations/create_branches"

module PactBroker
  module DB
    module DataMigrations
      describe CreateBranches do
        let(:db) { PactBroker::Domain::Version.db }

        subject { CreateBranches.call(db) }

        context "when there are no branch objects" do
          before do
            td.create_pacticipant("Foo")
              .create_version("1")
              .create_version("2")
              .create_version("3")
              .create_pacticipant("Bar")
              .create_version("10")
              .create_version("11")
              .create_version("12")

            db[:versions].where(number: ["1", "2"]).update(branch: "main")
            db[:versions].where(number: ["10", "11"]).update(branch: "main")
          end

          it "creates the missing branch versions" do
            subject
            expect(db[:branches].count).to eq 2
            expect(db[:branch_heads].count).to eq 2
            expect(db[:branch_versions].count).to eq 4
            expect(db[:branch_heads].order(:id).first[:version_id]).to eq db[:versions].where(number: "2").single_record[:id]
            expect(db[:branch_heads].order(:id).last[:version_id]).to eq db[:versions].where(number: "11").single_record[:id]
          end
        end

        context "when there is a branch already" do
          before do
            td.create_pacticipant("Foo")
              .create_version("1", branch: "main")
              .create_version("2")
              .create_version("3", branch: "main")
              .create_version("4")
            db[:versions].where(number: ["1", "2"]).update(branch: "main")
          end

          it "creates the missing branch versionsq" do
            subject
            expect(db[:branches].count).to eq 1
            expect(db[:branch_heads].count).to eq 1
            expect(db[:branch_versions].count).to eq 3
            expect(db[:branch_heads].order(:id).last[:version_id]).to eq db[:versions].where(number: "3").single_record[:id]
          end
        end
      end
    end
  end
end
