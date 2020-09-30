require 'pact_broker/db/clean'
require 'pact_broker/matrix/unresolved_selector'

IS_MYSQL = !!DB.mysql?

module PactBroker
  module DB
    # Inner queries don't work on MySQL. Seriously, MySQL???
    describe Clean, pending: IS_MYSQL  do
      let(:options) { {} }
      let(:db) { PactBroker::DB.connection }

      subject { Clean.call(PactBroker::DB.connection, options) }
      let(:latest_dev_selector) { PactBroker::Matrix::UnresolvedSelector.new(tag: "dev", latest: true) }
      let(:all_prod_selector) { PactBroker::Matrix::UnresolvedSelector.new(tag: "prod") }

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
          end

          let(:options) { { keep: [all_prod_selector, latest_dev_selector] } }

          it "does not delete the consumer versions specified" do
            expect(PactBroker::Domain::Version.where(number: "1").count).to be 1
            expect(PactBroker::Domain::Version.where(number: "3").count).to be 1
            expect(PactBroker::Domain::Version.where(number: "4").count).to be 1
            expect(PactBroker::Domain::Version.where(number: "5").count).to be 1
            expect(PactBroker::Domain::Version.where(number: "6").count).to be 1
            subject
            expect(PactBroker::Domain::Version.where(number: "1").count).to be 1
            expect(PactBroker::Domain::Version.where(number: "3").count).to be 1
            expect(PactBroker::Domain::Version.where(number: "4").count).to be 0
            expect(PactBroker::Domain::Version.where(number: "5").count).to be 1
            expect(PactBroker::Domain::Version.where(number: "6").count).to be 0
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

          it "does not delete the pact publication that belongs to the latest verification" do
            expect{ subject }.to_not change {
              PactBroker::Pacts::PactPublication.where(consumer_version: PactBroker::Domain::Version.where_pacticipant_name("Foo").where(number: "2")).count
            }
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

          let(:json_content_1) { { interactions: ['a', 'b']}.to_json }
          let(:json_content_2) { { interactions: ['a', 'c']}.to_json }

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
      end
    end
  end
end
