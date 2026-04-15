require "pact_broker/db/clean_incremental"
require "pact_broker/matrix/unresolved_selector"
require "timecop"

module PactBroker
  module DB
    describe CleanIncremental do
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
            td.create_environment("test")
              .create_pact_with_hierarchy("Foo", "1", "Bar")
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
              .create_deployed_version_for_consumer_version
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

          let(:keep_selectors) { [all_prod_selector, latest_dev_selector] }

          let(:options) { { keep: keep_selectors, limit: limit, dry_run: dry_run } }

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

          context "with the default selectors" do
            let(:options) { {} }

            it "doesn't blow up" do
              subject
            end
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

            # Randomly fails on github actions, never locally :shrug:
            it "returns info on what will be deleted", skip: ENV["CI"] == "true" do
              Approvals.verify(subject, :name => "clean_incremental_dry_run", format: :json)
            end
          end
        end

        context "with orphan pact versions" do
          before do
            # json_content_3 referenced by pact_publication for Foo v1
            td.create_pact_with_hierarchy("Foo", "1", "Bar", json_content_3).comment("Foo v1 kept because latest dev")
              .create_consumer_version_tag("dev")

            # json_content_4 referenced by a verification (but not a pact_publication)
            td.create_pact_with_hierarchy("Waffle", "0", "Meep", json_content_4)
              .create_verification(provider_version: "5", tag_names: ["dev"], comment: "Meep v5 kept because latest dev")
            PactBroker::Pacts::PactPublication.order(:id).last.delete

            # Create an orphan pact version
            pact_version_params = PactBroker::Pacts::PactVersion.first.to_hash
            pact_version_params.delete(:id)
            pact_version_params[:sha] = "1234"
            PactBroker::Pacts::PactVersion.create(pact_version_params)
          end

          let(:json_content_1) { { interactions: ["a", "b"]}.to_json }
          let(:json_content_2) { { interactions: ["a", "c"]}.to_json }
          let(:json_content_3) { { interactions: ["a", "f"]}.to_json }
          let(:json_content_4) { { interactions: ["a", "h"]}.to_json }

          let(:options) { { keep: [latest_dev_selector] } }

          it "deletes them" do
            expect { subject }.to change { PactBroker::Pacts::PactVersion.count }.by(-1)
          end
        end

        context "when there is a selector with a branch and a max age, and a selector with a max age only" do
          before do
            Timecop.freeze(Date.today - 20) do
              td.publish_pact(consumer_name: "Foo", provider_name: "Bar", consumer_version_number: "1", branch: "main")
              td.publish_pact(consumer_name: "Foo", provider_name: "Bar", consumer_version_number: "2", branch: "feat/foo")
            end
            Timecop.freeze(Date.today - 10) do
              td.publish_pact(consumer_name: "Foo", provider_name: "Bar", consumer_version_number: "3", branch: "main")
            end
            td.publish_pact(consumer_name: "Foo", provider_name: "Bar", consumer_version_number: "4", branch: "feat/foo")
          end

          let(:options) { { keep: [ { max_age: 5 }, { max_age: 15, branch: "main" }  ] } }

          let(:initial_versions) { [["1", "main"], ["2", "feat/foo"], ["3", "main"], ["4", "feat/foo"]] }
          let(:final_versions) { [["3", "main"], ["4", "feat/foo"]] }
          let(:versions_query) { PactBroker::Domain::Version.join(:branch_versions, { version_id: :id }).order(:order) }

          it "applies the max age correctly by branch" do
            expect { subject }.to change { versions_query.select_map([:number, :branch_name]) }.from(initial_versions).to(final_versions)
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

          # Keep all versions so only branch deletions are observable
          let(:keep_all_versions) { [PactBroker::DB::Clean::Selector.new(max_age: 999)] }

          context "when keep_branches is configured with a max_age" do
            let(:options) { { keep: keep_all_versions, keep_branches: [PactBroker::DB::Clean::BranchSelector.new(max_age: 90)] } }

            it "deletes branches whose updated_at is older than max_age" do
              expect { subject }.to change { PactBroker::Versions::Branch.where(name: "feat/old").count }.from(1).to(0)
            end

            it "keeps branches updated within max_age" do
              expect { subject }.to_not change { PactBroker::Versions::Branch.where(name: "feat/fresh").count }
            end

            it "does not delete the versions associated with the stale branch" do
              expect { subject }.to_not change { PactBroker::Domain::Version.where(number: "1").count }
            end
          end

          context "when the pacticipant has a main_branch set" do
            before do
              Timecop.freeze(Date.today - 100) do
                # Publish a version on the main branch, making it "stale" by age
                td.publish_pact(consumer_name: "Foo", provider_name: "Bar", consumer_version_number: "4", branch: "main-protected")
              end
              PactBroker::Domain::Pacticipant.where(name: "Foo").update(main_branch: "main-protected")
            end

            let(:options) { { keep: keep_all_versions, keep_branches: [PactBroker::DB::Clean::BranchSelector.new(max_age: 90)] } }

            it "never deletes the main branch even when stale" do
              expect { subject }.to_not change { PactBroker::Versions::Branch.where(name: "main-protected").count }
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

          context "when keep_branches is nil (disabled)" do
            let(:options) { { keep: keep_all_versions, keep_branches: nil } }

            it "does not delete any branches" do
              expect { subject }.to_not change { PactBroker::Versions::Branch.count }
            end
          end

          context "when keep_branches is an empty array (disabled)" do
            let(:options) { { keep: keep_all_versions, keep_branches: [] } }

            it "does not delete any branches" do
              expect { subject }.to_not change { PactBroker::Versions::Branch.count }
            end
          end

          context "with the default options (no keep_branches specified)" do
            let(:options) { {} }

            it "applies the DEFAULT_KEEP_BRANCH_SELECTORS (90 days)" do
              # feat/old was published 100 days ago, should be deleted by default
              expect { subject }.to change { PactBroker::Versions::Branch.where(name: "feat/old").count }.from(1).to(0)
            end

            it "keeps branches updated within the default 90-day window" do
              expect { subject }.to_not change { PactBroker::Versions::Branch.where(name: "feat/fresh").count }
            end
          end
        end
      end
    end
  end
end
