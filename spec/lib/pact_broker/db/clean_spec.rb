require "pact_broker/db/clean"
require "pact_broker/matrix/unresolved_selector"
require "timecop"

module PactBroker
  module DB
    # Inner queries don't work on MySQL. Seriously, MySQL???
    describe Clean, pending: !!DB.mysql?  do

      def pact_publication_count_for(consumer_name, version_number)
        PactBroker::Pacts::PactPublication.where(consumer_version: PactBroker::Domain::Version.where_pacticipant_name(consumer_name).where(number: version_number)).count
      end

      let(:options) { {} }
      let(:db) { PactBroker::DB.connection }

      subject { Clean.call(PactBroker::DB.connection, options) }
      let(:latest_dev_selector) { { tag: "dev", latest: true } }
      let(:all_prod_selector) { { tag: "prod" } }

      describe ".call"do
        context "when there are specified versions to keep" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_consumer_version_tag("prod")
              .create_consumer_version_tag("dev")
              .create_consumer_version("3", tag_names: %w{prod})
              .create_pact
              .create_consumer_version("4", tag_names: %w{dev})
              .create_pact
              .create_consumer_version("5", tag_names: %w{dev})
              .create_pact
              .create_consumer_version("6", tag_names: %w{foo})
              .create_pact
              .create_consumer_version("7")
              .create_pact
          end

          let(:options) { { keep: [all_prod_selector, latest_dev_selector] } }

          it "does not delete the consumer versions specified" do
            expect(PactBroker::Domain::Version.where(number: "1").count).to be 1
            expect(PactBroker::Domain::Version.where(number: "3").count).to be 1
            expect(PactBroker::Domain::Version.where(number: "4").count).to be 1
            expect(PactBroker::Domain::Version.where(number: "5").count).to be 1
            expect(PactBroker::Domain::Version.where(number: "6").count).to be 1
            expect(PactBroker::Domain::Version.where(number: "7").count).to be 1
            subject
            expect(PactBroker::Domain::Version.where(number: "1").count).to be 1
            expect(PactBroker::Domain::Version.where(number: "3").count).to be 1
            expect(PactBroker::Domain::Version.where(number: "4").count).to be 0
            expect(PactBroker::Domain::Version.where(number: "5").count).to be 1
            expect(PactBroker::Domain::Version.where(number: "6").count).to be 0
            expect(PactBroker::Domain::Version.where(number: "7").count).to be 1 # doesn't delete overall latest
          end
        end

        context "when the latest pact for a tag does not belong to the latest version for a tag" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar").comment("delete, not latest pact for dev")
              .create_consumer_version_tag("dev")
              .create_pact_with_hierarchy("Foo", "2", "Bar").comment("keep, latest pact for dev")
              .create_consumer_version_tag("dev")
              .create_consumer_version("3").comment("keep, latest version for dev")
              .create_consumer_version_tag("dev")
          end

          it "deletes the not-latest pact" do
            expect { subject }.to change { pact_publication_count_for("Foo", "1") }.by(-1)
          end

          it "does not delete the pact latest" do
            expect { subject }.to_not change { pact_publication_count_for("Foo", "2") }
          end
        end

        context "when a verification for the latest tagged version belongs to a pact that is not the latest tagged version" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar", td.random_json_content("Foo", "Bar"))
              .create_consumer_version_tag("dev").comment("delete, not latest, not verified by latest Bar")
              .create_verification(provider_version: "3", tag_names: "dev").comment("delete, not latest")
              .create_pact_with_hierarchy("Foo", "2", "Bar", td.random_json_content("Foo", "Bar"))
              .create_consumer_version_tag("dev").comment("can't delete because it is verified by the latest dev version of the provider")
              .create_verification(provider_version: "4", tag_names: "dev").comment("keep")
              .create_pact_with_hierarchy("Foo", "3", "Bar", td.random_json_content("Foo", "Bar"))
              .create_consumer_version_tag("dev").comment("keep")
          end

          let(:options) { { keep: [latest_dev_selector] } }

          it "does not delete the latest verification" do
            expect{ subject }.to_not change {
              PactBroker::Domain::Verification.where(provider_version: PactBroker::Domain::Version.where_pacticipant_name("Bar").where(number: "4")).count
            }
          end

          it "deletes the non-latest verification" do
            expect{ subject }.to change {
              PactBroker::Domain::Verification.where(provider_version: PactBroker::Domain::Version.where_pacticipant_name("Bar").where(number: "3")).count
            }.by(-1)
          end

          it "deletes the pact publication that does not belongs to the latest verification" do
            expect{ subject }.to change {
              PactBroker::Pacts::PactPublication.where(consumer_version: PactBroker::Domain::Version.where_pacticipant_name("Foo").where(number: "1")).count
            }.by(-1)
          end
        end

        context "with orphan pact versions" do
          before do
            # Create a pact that will not be deleted
            td.create_pact_with_hierarchy("Foo", "0", "Bar", json_content_1)
              .create_consumer_version_tag("dev")
            # Create an orphan pact version
            pact_version_params = PactBroker::Pacts::PactVersion.first.to_hash
            pact_version_params.delete(:id)
            pact_version_params[:sha] = "1234"
            PactBroker::Pacts::PactVersion.create(pact_version_params)
          end

          let(:json_content_1) { { interactions: ["a", "b"]}.to_json }
          let(:json_content_2) { { interactions: ["a", "c"]}.to_json }

          let(:options) { { keep: [latest_dev_selector] } }

          it "deletes them" do
            expect { subject }.to change { PactBroker::Pacts::PactVersion.count }.by(-1)
          end
        end

        context "with triggered and executed webhooks" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_consumer_version_tag("dev").comment("delete")
              .create_webhook
              .create_triggered_webhook
              .create_webhook_execution
              .add_day
              .create_pact_with_hierarchy("Foo", "2", "Bar")
              .create_consumer_version_tag("dev").comment("keep")
              .create_webhook
              .create_triggered_webhook
              .create_webhook_execution
          end

          it "deletes the ones associated with the deleted pacts" do
            expect { subject }.to change { PactBroker::Webhooks::TriggeredWebhook.count }.by(-1)
          end
        end

        context "stale branch cleanup" do
          before do
            Timecop.freeze(Date.today - 100) do
              td.publish_pact(consumer_name: "Foo", provider_name: "Bar", consumer_version_number: "1", branch: "feat/old")
            end
            Timecop.freeze(Date.today - 50) do
              td.publish_pact(consumer_name: "Foo", provider_name: "Bar", consumer_version_number: "2", branch: "feat/fresh")
              td.publish_pact(consumer_name: "Foo", provider_name: "Bar", consumer_version_number: "3", branch: "main")
            end
          end

          # Keep all versions so branch deletion is what's observable
          let(:keep_all_versions) { [{ max_age: 999 }] }

          context "when keep_branches is configured with a max_age" do
            let(:options) { { keep: keep_all_versions, keep_branches: [PactBroker::DB::Clean::BranchSelector.new(max_age: 90)] } }

            it "deletes branches whose updated_at is older than max_age" do
              expect { subject }.to change { PactBroker::Versions::Branch.where(name: "feat/old").count }.from(1).to(0)
            end

            it "keeps branches updated within max_age" do
              expect { subject }.to_not change { PactBroker::Versions::Branch.where(name: "feat/fresh").count }
            end

            it "returns the number of deleted branches in the deleted counts" do
              expect(subject[:deleted][:stale_branches]).to eq 1
            end
          end

          context "when the pacticipant has a main_branch set" do
            before do
              Timecop.freeze(Date.today - 100) do
                td.publish_pact(consumer_name: "Foo", provider_name: "Bar", consumer_version_number: "4", branch: "main-protected")
              end
              PactBroker::Domain::Pacticipant.where(name: "Foo").update(main_branch: "main-protected")
            end

            let(:options) { { keep: keep_all_versions, keep_branches: [PactBroker::DB::Clean::BranchSelector.new(max_age: 90)] } }

            it "never deletes the main branch even when stale" do
              expect { subject }.to_not change { PactBroker::Versions::Branch.where(name: "main-protected").count }
            end
          end

          context "when two pacticipants have a branch with the same name but only one declares it as main_branch" do
            before do
              Timecop.freeze(Date.today - 100) do
                td.publish_pact(consumer_name: "ConsumerA", provider_name: "ProviderX", consumer_version_number: "1", branch: "shared-main")
                td.publish_pact(consumer_name: "ConsumerB", provider_name: "ProviderX", consumer_version_number: "1", branch: "shared-main")
              end
              PactBroker::Domain::Pacticipant.where(name: "ConsumerA").update(main_branch: "shared-main")
              # ConsumerB intentionally has no main_branch set
            end

            let(:options) { { keep: keep_all_versions, keep_branches: [PactBroker::DB::Clean::BranchSelector.new(max_age: 90)] } }

            def branch_count_for(pacticipant_name, branch_name)
              pacticipant_id = PactBroker::Domain::Pacticipant.where(name: pacticipant_name).get(:id)
              PactBroker::Versions::Branch.where(pacticipant_id: pacticipant_id, name: branch_name).count
            end

            it "keeps the stale 'shared-main' branch belonging to the pacticipant that declares it as main_branch" do
              expect { subject }.to_not change { branch_count_for("ConsumerA", "shared-main") }.from(1)
            end

            it "deletes the stale 'shared-main' branch belonging to the pacticipant that does not declare it as main_branch" do
              expect { subject }.to change { branch_count_for("ConsumerB", "shared-main") }.from(1).to(0)
            end
          end

          context "when a branch name is listed in keep_branches selectors" do
            let(:options) do
              {
                keep: keep_all_versions,
                keep_branches: [
                  PactBroker::DB::Clean::BranchSelector.new(max_age: 90),
                  PactBroker::DB::Clean::BranchSelector.new(branch: ["feat/old"])
                ]
              }
            end

            it "keeps explicitly named branches even when stale" do
              expect { subject }.to_not change { PactBroker::Versions::Branch.where(name: "feat/old").count }
            end
          end

          context "when keep_branches is nil" do
            let(:options) { { keep: keep_all_versions, keep_branches: nil } }

            it "does not delete any branches" do
              expect { subject }.to_not change { PactBroker::Versions::Branch.count }
            end

            it "reports zero stale branches deleted" do
              expect(subject[:deleted][:stale_branches]).to eq 0
            end
          end

          context "when keep_branches is an empty array" do
            let(:options) { { keep: keep_all_versions, keep_branches: [] } }

            it "does not delete any branches" do
              expect { subject }.to_not change { PactBroker::Versions::Branch.count }
            end

            it "reports zero stale branches deleted" do
              expect(subject[:deleted][:stale_branches]).to eq 0
            end
          end

          context "when keep_branches is not specified in the options" do
            let(:options) { { keep: keep_all_versions } }

            it "does not delete any branches" do
              expect { subject }.to_not change { PactBroker::Versions::Branch.count }
            end
          end
        end
      end
    end
  end
end
