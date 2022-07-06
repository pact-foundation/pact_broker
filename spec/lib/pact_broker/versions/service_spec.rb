require "pact_broker/versions/service"

module PactBroker
  module Versions
    describe Service do
      describe ".maybe_set_version_branch_from_tag" do
        before do
          allow(PactBroker.configuration).to receive(:use_first_tag_as_branch).and_return(use_first_tag_as_branch)
        end

        let(:pacticipant_name) { "test_pacticipant" }
        let(:version_number) { "1.2.3" }
        let(:tag_name) { "prod" }

        subject { Service.maybe_set_version_branch_from_tag(td.find_version(pacticipant_name, version_number), tag_name) }

        context "when use_first_tag_as_branch is true" do
          let(:use_first_tag_as_branch) { true }

          context "when there is already a tag" do
            before do
              td.create_consumer(pacticipant_name)
                .create_consumer_version(version_number, tag_name: "foo")
            end

            it "does not set the branch" do
              subject
              expect(td.find_version(pacticipant_name, version_number).branch_names).to be_empty
            end
          end

          context "when the branch is already set" do
            before do
              td.create_consumer(pacticipant_name)
                .create_consumer_version(version_number, branch: "foo")
            end

            it "does not update the branch" do
              subject
              expect(td.find_version(pacticipant_name, version_number).branch_names).to eq ["foo"]
            end
          end

          context "when use_first_tag_as_branch is false" do
            before do
              td.create_consumer(pacticipant_name)
                .create_consumer_version(version_number)
            end

            let(:use_first_tag_as_branch) { false }

            it "does not set the branch" do
              subject
              expect(td.find_version(pacticipant_name, version_number).branch_names).to be_empty
            end
          end

          context "when the version was outside of the time difference limit" do
            before do
              version = td.create_consumer(pacticipant_name)
                .create_consumer_version(version_number)
                .and_return(:consumer_version)

              version.update(created_at: created_at)
              allow(PactBroker.configuration).to receive(:use_first_tag_as_branch_time_limit).and_return(10)
              allow(Time).to receive(:now).and_return(td.in_utc { Time.new(2021, 1, 2, 10, 10, 11) } )
            end

            let(:created_at) { td.in_utc { Time.new(2021, 1, 2, 10, 10, 0) }.to_datetime  }
            let(:one_second) { 1/(24 * 60 * 60) }

            it "does not set the branch" do
              subject
              expect(td.find_version(pacticipant_name, version_number).branch_names).to be_empty
            end
          end

          context "when the version was created within the limit" do
            before do
              version = td
                .create_consumer(pacticipant_name)
                .create_consumer_version(version_number)
                .and_return(:consumer_version)

              version.update(created_at: created_at)
              allow(PactBroker.configuration).to receive(:use_first_tag_as_branch_time_limit).and_return(10)
              allow(Time).to receive(:now).and_return(td.in_utc { Time.new(2021, 1, 2, 10, 10, 10) } )
            end

            let(:created_at) { td.in_utc { Time.new(2021, 1, 2, 10, 10, 0) }.to_datetime  }
            let(:one_second) { 1/(24 * 60 * 60) }

            it "sets the branch" do
              subject
              expect(td.find_version(pacticipant_name, version_number).branch_names).to include "prod"
            end
          end
        end
      end
      describe ".delete" do
        let!(:version) do
          td
            .create_consumer
            .create_provider
            .create_consumer_version("1.2.3")
            .create_consumer_version_tag("prod")
            .create_pact
            .create_verification(provider_version: "1.0.0")
            .create_webhook
            .create_triggered_webhook
            .create_webhook_execution
            .and_return(:consumer_version)
        end

        subject { Service.delete(version) }

        it "deletes the pact publication" do
          expect{ subject }.to change { PactBroker::Pacts::PactPublication.count }.by(-1)
        end

        it "deletes the tags" do
          expect{ subject }.to change { PactBroker::Domain::Tag.count }.by(-1)
        end

        it "deletes the version" do
          expect{ subject }.to change { PactBroker::Domain::Version.count }.by(-1)
        end

        context "when deleting a provider version" do
          it "deletes associated verifications" do
            expect { Service.delete(td.provider_version ) }. to change { PactBroker::Domain::Verification.count }.by(-1)
          end
        end
      end
    end
  end
end
