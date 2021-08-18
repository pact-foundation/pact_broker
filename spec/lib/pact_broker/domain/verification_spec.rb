require "pact_broker/domain/verification"

module PactBroker

  module Domain
    describe Verification do
      describe "latest_by_pact_version" do
        before do
          td.create_pact_with_hierarchy("Foo", "10", "Bar")
            .create_verification(provider_version: "3", number: 1)
            .create_verification(provider_version: "4", number: 2)
            .create_pact_with_hierarchy("Foo2", "10", "Bar2")
            .create_verification(provider_version: "30", number: 1)
            .create_verification(provider_version: "31", number: 2)
        end

        subject { Verification.latest_by_pact_version.order(:id).all }

        it "returns the latest by pact version" do
          expect(subject.size).to eq 2
          expect(subject.collect(&:provider_version_number).sort).to eq ["31", "4"]
        end
      end
      describe "latest_verifications_for_all_consumer_version_tags" do
        before do
          td.create_pact_with_verification_and_tags("Foo", "1", ["fmain"], "Bar", "2")
            .create_pact_with_verification_and_tags("Foo", "3", ["fmain"], "Bar", "4")
            .create_pact_with_verification_and_tags("Foo", "5", ["fmain"], "Bar", "5")
            .create_pact_with_verification_and_tags("Foo", "6", ["other"], "Bar", "5")
            .create_pact_with_verification_and_tags("Foo2", "6", ["fprod"], "Bar", "7")
            .create_pact_with_verification_and_tags("Ignored", "6", ["fmain"], "Bar", "8")
        end

        subject { Verification.latest_verifications_for_all_consumer_version_tags.all }

        it "returns the same number of rows as the view" do
          expect(subject.size).to eq Verification.db[:latest_verifications_for_consumer_version_tags].count
        end

        it "allows eager" do
          expect(Verification.latest_verifications_for_all_consumer_version_tags.eager(:provider_version).all.first.provider_version.number).to_not be nil
        end
      end

      describe "latest_verifications_for_consumer_version_tags" do
        before do
          td.create_pact_with_verification_and_tags("Foo", "1", ["fmain"], "Bar", "2")
            .create_pact_with_verification_and_tags("Foo", "3", ["fmain"], "Bar", "4")
            .create_pact_with_verification_and_tags("Foo", "5", ["fmain"], "Bar", "5")
            .create_pact_with_verification_and_tags("Foo", "6", ["other"], "Bar", "5")
            .create_pact_with_verification_and_tags("Foo2", "6", ["fprod"], "Bar", "7")
            .create_pact_with_verification_and_tags("Ignored", "6", ["fmain"], "Bar", "8")
        end

        let(:consumer_ids) { PactBroker::Domain::Pacticipant.where(name: ["Foo", "Foo2"]).all.collect(&:id) }

        subject { Verification.latest_verifications_for_consumer_version_tags(consumer_ids, ["fmain", "fprod"]).order(:id) }

        it "returns the latest verifications for the given consumer ids and consumer version tag names" do
          expect(subject.first.provider_version_number).to eq "5"
          expect(subject.first.consumer_name).to eq "Foo"
          expect(subject.first.consumer_version_tag_name).to eq "fmain"
          expect(subject.last.provider_version_number).to eq "7"
          expect(subject.last.consumer_name).to eq "Foo2"
          expect(subject.last.consumer_version_tag_name).to eq "fprod"
        end

        it "allows eager" do
          expect(subject.eager(:provider_version).all.first.provider_version.number).to eq "5"
        end
      end

      describe "delete" do
        before do
          td.create_pact_with_hierarchy("Foo", "1", "Bar")
            .create_verification_webhook
            .create_verification(provider_version: "2")
            .create_triggered_webhook
            .create_webhook_execution
        end

        it "deletes stuff" do
          Verification.delete
        end
      end

      describe "#save" do
        let!(:verification) do
          TestDataBuilder.new
            .create_pact_with_hierarchy("A", "1", "B")
            .create_verification(test_results: {"some" => "thing"})
            .and_return(:verification)
        end

        it "saves and loads the test_results" do
          expect(Verification.find(id: verification.id).test_results).to eq({ "some" => "thing" })
        end
      end

      describe "#from_latest_main_version?" do
        before do
          allow(PactBroker.configuration).to receive(:use_first_tag_as_branch).and_return(false)
        end


        subject { verification.from_latest_main_version? }


        context "when the tag name matches the main branch name" do
          let!(:verification) do
            td.create_consumer
              .create_provider("Bar", main_branch: "develop")
              .create_consumer_version
              .create_pact
              .create_verification(provider_version: "2", tag_names: ["develop"])
              .and_return(:verification)
              .reload
          end

          context "it is the latest" do
            it { is_expected.to be true }
          end

          context "it is not the latest" do
            before do
              verification
              td.create_provider_version("3", tag_names: ["develop"] )
            end

            it { is_expected.to be false }
          end
        end

        context "when the branch name matches the main branch name" do
          let!(:verification) do
            td.create_consumer
              .create_provider("Bar", main_branch: "develop")
              .create_consumer_version
              .create_pact
              .create_verification(provider_version: "2", branch: "develop")
              .and_return(:verification)
              .reload
          end

          context "it is the latest" do
            it { is_expected.to be true }
          end

          context "it is not the latest" do
            before do
              verification
              td.create_provider_version("3", branch: ["develop"] )
            end

            it { is_expected.to be false }
          end
        end

        context "the tag and branch do not match" do
          let!(:verification) do
            td.create_consumer
              .create_provider("Bar", main_branch: "develop")
              .create_consumer_version
              .create_pact
              .create_verification(provider_version: "2", tag_names: ["foo"], branch: "bar")
              .and_return(:verification)
              .reload
          end

          it { is_expected.to be false }
        end
      end
    end
  end
end
