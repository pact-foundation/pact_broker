require 'pact_broker/db/delete_overwritten_data'

module PactBroker
  module DB
    describe DeleteOverwrittenData, pending: !!DB.mysql? do
      describe ".call" do
        let(:db) { PactBroker::DB.connection }
        subject { DeleteOverwrittenData.call(db, before: before_date) }
        let(:before_date) { nil }

        context "when a pact is overwritten" do
          let!(:pact_to_delete) { td.create_everything_for_an_integration.and_return(:pact) }
          let!(:pact_to_keep) { td.revise_pact.and_return(:pact) }


          it "deletes the overwritten pact" do
            expect { subject }.to change{ db[:pact_publications].where(id: pact_to_delete.id).count }.by(-1)
          end

          it "does not delete the most recent pact" do
            expect { subject }.to_not change{ db[:pact_publications].where(id: pact_to_keep.id).count }
          end

          it "returns a report" do
            expect(subject[:deleted][:pact_publications]).to eq 1
            expect(subject[:kept][:pact_publications]).to eq 1
          end
        end

        context "when a pact has multiple verifications" do
          let!(:verification_to_delete) do
            td.create_pact_with_hierarchy
              .create_verification(provider_version: "1", success: false)
              .and_return(:verification)
          end

          let!(:verification_to_keep) { td.create_verification(provider_version: "1", number: 2, success: true).and_return(:verification) }

          it "deletes the overwritten verification" do
            expect { subject }.to change{ db[:verifications].where(id: verification_to_delete.id).count }.by(-1)
          end

          it "does not delete the most recent verification" do
            expect { subject }.to_not change{ db[:verifications].where(id: verification_to_keep.id).count }
          end

          it "returns a report" do
            expect(subject[:deleted][:verification_results]).to eq 1
            expect(subject[:kept][:verification_results]).to eq 1
          end
        end

        context "when a pact version is orphaned" do
          before do
            td.create_pact_with_verification.comment("this one will still have the verification, so can't be deleted")
              .revise_pact.comment("this one can be deleted")
              .revise_pact.comment("this one will still have a pact publication, so can't be deleted")
          end

          it "is deleted" do
            expect { subject }.to change{ db[:pact_versions].count }.by(-1)
          end

          it "returns a report" do
            expect(subject[:deleted][:pact_versions]).to eq 1
            expect(subject[:kept][:pact_versions]).to eq 2
          end
        end

        context "when the pact publication is created after the before date" do
          before do
            td.set_now(before_date + 1)
              .create_pact_with_hierarchy
              .revise_pact
          end

          let(:before_date) { DateTime.new(2010, 2, 5) }

          it "doesn't delete the data" do
            expect { subject }.to_not change { db[:pact_publications].count }
          end
        end

        context "when the verification is created after the before date" do
          before do
            td.set_now(before_date + 1)
              .create_pact_with_hierarchy
              .create_verification(provider_version: "1", success: false)
              .create_verification(provider_version: "1", success: true, number: 2)
          end

          let(:before_date) { DateTime.new(2010, 2, 5) }

          it "doesn't delete the data" do
            expect { subject }.to_not change { db[:verifications].count }
          end
        end
      end
    end
  end
end
