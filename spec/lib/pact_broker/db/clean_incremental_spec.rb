require "pact_broker/db/clean_incremental"
require "pact_broker/matrix/unresolved_selector"

module PactBroker
  module DB
    # Inner queries don't work on MySQL. Seriously, MySQL???
    describe CleanIncremental, skip: true  do

      def pact_publication_count_for(consumer_name, version_number)
        PactBroker::Pacts::PactPublication.where(consumer_version: PactBroker::Domain::Version.where_pacticipant_name(consumer_name).where(number: version_number)).count
      end

      let(:options) { {} }
      let(:db) { PactBroker::DB.connection }


      let(:latest_dev_selector) { PactBroker::Matrix::UnresolvedSelector.new(tag: "dev", latest: true) }
      let(:all_prod_selector) { PactBroker::Matrix::UnresolvedSelector.new(tag: "prod") }
      let(:limit) { 3 }
      let(:dry_run) { false }

      subject { CleanIncremental.call(PactBroker::DB.connection, options) }

      describe ".call"do
        context "when there are specified versions to keep" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_webhook
              .create_triggered_webhook
              .create_webhook_execution
              .create_consumer_version_tag("prod").comment("keep as one of prod")
              .create_consumer_version_tag("dev")
              .add_day
              .create_consumer_version("2").comment("DELETE")
              .add_day
              .create_consumer_version("3", tag_names: %w{prod}).comment("keep as one of prod")
              .create_pact
              .add_day
              .create_consumer_version("4", tag_names: %w{dev}).comment("DELETE as not latest")
              .create_pact
              .add_day
              .create_consumer_version("5", tag_names: %w{dev}).comment("keep as latest dev")
              .create_pact
              .add_day
              .create_consumer_version("6", tag_names: %w{foo}).comment("DELETE as not specified")
              .create_pact
              .add_day
              .create_consumer_version("7").comment("keep as deletion limit is 3")
              .create_pact
          end

          let(:options) { { keep: [all_prod_selector, latest_dev_selector], limit: limit, dry_run: dry_run } }

          it "does not delete the consumer versions specified" do
            expect(PactBroker::Domain::Version.where(number: "1").count).to be 1
            expect(PactBroker::Domain::Version.where(number: "2").count).to be 1
            expect(PactBroker::Domain::Version.where(number: "3").count).to be 1
            expect(PactBroker::Domain::Version.where(number: "4").count).to be 1
            expect(PactBroker::Domain::Version.where(number: "5").count).to be 1
            expect(PactBroker::Domain::Version.where(number: "6").count).to be 1
            expect(PactBroker::Domain::Version.where(number: "7").count).to be 1
            subject
            expect(PactBroker::Domain::Version.where(number: "1").count).to be 1
            expect(PactBroker::Domain::Version.where(number: "2").count).to be 0
            expect(PactBroker::Domain::Version.where(number: "3").count).to be 1
            expect(PactBroker::Domain::Version.where(number: "4").count).to be 0
            expect(PactBroker::Domain::Version.where(number: "5").count).to be 1
            expect(PactBroker::Domain::Version.where(number: "6").count).to be 0
            expect(PactBroker::Domain::Version.where(number: "7").count).to be 1
          end

          context "when dry_run: true" do
            before do
              td.create_pact_with_hierarchy("Meep", "2", "Moop")
                .create_consumer_version_tag("foop")
                .create_consumer_version("3")
                .create_consumer_version_tag("blah")
            end

            let(:dry_run) { true }

            it "doesn't delete anything" do
              expect { subject }.to_not change { PactBroker::Domain::Version.count }
            end

            it "returns info on what will be deleted" do
              Approvals.verify(subject, :name => "clean_incremental_dry_run", format: :json)
            end
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
      end
    end
  end
end
