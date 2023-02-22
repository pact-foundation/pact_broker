require "pact_broker/db/delete_overwritten_data"

module PactBroker
  module DB
    describe DeleteOverwrittenData, skip: !!DB.mysql? do
      describe ".call" do
        let(:db) { PactBroker::DB.connection }
        let(:max_age) { nil }
        let(:dry_run) { nil }
        let(:limit) { nil }

        subject { DeleteOverwrittenData.call(db, max_age: max_age, limit: limit, dry_run: dry_run) }

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
            expect(subject[:pact_publications]).to eq(deleted: 1, kept: 1)
          end

          context "when dry_run is true" do
            let(:dry_run) { true }

            it "does not delete anything" do
              expect { subject }.to_not change{ db[:pact_publications].count }
            end

            it "returns a report" do
              expect(subject[:pact_publications]).to eq(toDelete: 1, toKeep: 1)
            end
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
            expect(subject[:verification_results][:deleted]).to eq 1
            expect(subject[:verification_results][:kept]).to eq 1
          end
        end

        context "when a pact version is orphaned" do
          before do
            td.create_pact_with_verification.comment("this one will still have the verification, so can't be deleted")
              .create_pact_version_without_publication.comment("will be deleted")
              .create_pact_version_without_publication.comment("will be kept because of limit")
          end

          let(:limit) { 1 }

          it "is deleted" do
            expect { subject }.to change{ db[:pact_versions].count }.by(-1)
          end

          it "returns a report" do
            expect(subject[:pact_versions]).to eq(deleted: 1, kept: 2)
          end

          context "when dry_run is true" do
            let(:dry_run) { true }

            it "does not delete anything" do
              expect { subject }.to_not change{ db[:pact_versions].count }
            end
          end
        end

        context "when the pact publication is younger than the max age" do
          before do
            td.set_now(DateTime.now - 3)
              .create_pact_with_hierarchy
              .revise_pact
          end

          let(:max_age) { 4 }

          it "doesn't delete the data" do
            expect { subject }.to_not change { db[:pact_publications].count }
          end
        end

        context "when the verification is younger than the max age" do
          before do
            td.set_now(DateTime.now - 3)
              .create_pact_with_hierarchy
              .create_verification(provider_version: "1", success: false)
              .create_verification(provider_version: "1", success: true, number: 2)
          end

          let(:max_age) { 4 }

          it "doesn't delete the data" do
            expect { subject }.to_not change { db[:verifications].count }
          end
        end

        context "when there are triggered webhooks and executions" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_webhook
              .create_triggered_webhook
              .create_webhook_execution
              .create_triggered_webhook.comment("latest")
              .create_webhook_execution
              .create_pact_with_hierarchy("Foo1", "1", "Bar1")
              .create_webhook
              .create_triggered_webhook
              .create_webhook_execution
              .create_triggered_webhook.comment("latest")
              .create_webhook_execution
          end

          let(:limit) { 3 }

          it "deletes all but the latest triggered webhooks, considering the limit" do
            expect { subject }.to change { PactBroker::Webhooks::TriggeredWebhook.count }.by(-2)
          end

          it "returns a report" do
            expect(subject[:triggered_webhooks]).to eq(deleted: 2, kept: 2)
          end

          context "when dry_run is true" do
            let(:dry_run) { true }

            it "does not delete anything" do
              expect { subject }.to_not change{ PactBroker::Webhooks::TriggeredWebhook.count }
            end

            it "returns a report" do
              expect(subject[:triggered_webhooks]).to eq(toDelete: 2, toKeep: 2)
            end
          end

          context "when all the records are younger than the max age" do
            let(:max_age) { 1 }

            it "doesn't delete anything" do
              expect { subject }.to_not change { PactBroker::Webhooks::TriggeredWebhook.count }
            end
          end
        end
      end
    end
  end
end
