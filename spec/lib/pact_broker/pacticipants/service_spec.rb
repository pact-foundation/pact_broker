require "pact_broker/pacticipants/service"
require "pact_broker/domain/tag"
require "pact_broker/domain/pact"

module PactBroker
  module Pacticipants
    describe Service do
      before do
        allow(Service).to receive(:logger).and_return(logger)
      end

      let(:logger) { double("logger").as_null_object }

      subject { Service }

      describe ".messages_for_potential_duplicate_pacticipants" do
        let(:base_url) { "http://example.org" }
        let(:fred_duplicates) { [double("Frederich pacticipant")] }
        let(:mary_dulicates) { [double("Marta pacticipant")] }

        before do
          allow(Service).to receive(:find_potential_duplicate_pacticipants).with("Fred").and_return(fred_duplicates)
          allow(Service).to receive(:find_potential_duplicate_pacticipants).with("Mary").and_return(mary_dulicates)
          allow(Service).to receive(:potential_duplicate_pacticipant_message).and_return("message1", "message2")
        end

        subject { Service.messages_for_potential_duplicate_pacticipants ["Fred", "Mary"], base_url }

        it "finds the potential duplicates for each name" do
          expect(Service).to receive(:find_potential_duplicate_pacticipants).with("Fred")
          expect(Service).to receive(:find_potential_duplicate_pacticipants).with("Mary")
          subject
        end

        context "when there are potential duplicates" do
          it "creates a message for each dupliate" do
            expect(Service).to receive(:potential_duplicate_pacticipant_message).with("Fred", fred_duplicates, base_url)
            expect(Service).to receive(:potential_duplicate_pacticipant_message).with("Mary", mary_dulicates, base_url)
            subject
          end

          it "returns an array of messages" do
            expect(subject).to eq ["message1", "message2"]
          end
        end

        context "when there are no potential duplicates" do
          let(:fred_duplicates) { [] }
          let(:mary_dulicates) { [] }

          it "returns an empty array" do
            expect(subject).to eq []
          end
        end
      end

      describe ".find_potential_duplicate_pacticipants" do
        let(:pacticipant_name) { "pacticipant_name" }
        let(:duplicates) { ["Fred", "Mary"] }
        let(:pacticipant_names) { double("pacticipant_names") }
        let(:fred) { double("fred pacticipant")}
        let(:mary) { double("mary pacticipant")}
        let(:pacticipant_repository) { instance_double(PactBroker::Pacticipants::Repository)}

        before do
          allow(PactBroker::Pacticipants::FindPotentialDuplicatePacticipantNames).to receive(:call).and_return(duplicates)
          allow(PactBroker::Pacticipants::Repository).to receive(:new).and_return(pacticipant_repository)
          allow(pacticipant_repository).to receive(:pacticipant_names).and_return(pacticipant_names)
          allow(pacticipant_repository).to receive(:find_by_name).with("Fred").and_return(fred)
          allow(pacticipant_repository).to receive(:find_by_name).with("Mary").and_return(mary)
        end

        it "finds all the pacticipant names" do
          expect(pacticipant_repository).to receive(:pacticipant_names)
          subject.find_potential_duplicate_pacticipants pacticipant_name
        end

        it "calculates the duplicates" do
          expect(PactBroker::Pacticipants::FindPotentialDuplicatePacticipantNames).to receive(:call).with(pacticipant_name, pacticipant_names)
          subject.find_potential_duplicate_pacticipants pacticipant_name
        end

        it "retrieves the pacticipants by name" do
          expect(pacticipant_repository).to receive(:find_by_name).with("Fred")
          expect(pacticipant_repository).to receive(:find_by_name).with("Mary")
          subject.find_potential_duplicate_pacticipants pacticipant_name
        end

        it "returns the duplicate pacticipants" do
          expect(subject.find_potential_duplicate_pacticipants(pacticipant_name)).to eq [fred, mary]
        end

        it "logs the names" do
          expect(logger).to receive(:info).with(/pacticipant_name.*Fred, Mary/)
          subject.find_potential_duplicate_pacticipants pacticipant_name
        end
      end

      describe ".maybe_set_main_branch" do
        before do
          allow(PactBroker.configuration).to receive(:auto_detect_main_branch).and_return(true)
          allow(PactBroker.configuration).to receive(:main_branch_candidates).and_return(["foo", "bar"])
          td.create_pacticipant("Foo", main_branch: main_branch)
        end

        let(:main_branch) { nil }

        subject { Service.maybe_set_main_branch(td.find_pacticipant("Foo"), "bar") }

        context "when the main branch is nil and auto_detect_main_branch=true and the potential branch is in the list of candidate main branch names" do
          it "sets the main branch" do
            expect(subject.main_branch).to eq "bar"
          end
        end

        context "when the branch is already set" do
          let(:main_branch) { "main" }

          it "does not overwrite it" do
            expect(subject.main_branch).to eq "main"
          end
        end
      end

      describe "delete" do
        before do
          td.create_consumer("Consumer")
            .create_label("finance")
            .create_consumer_version("2.3.4")
            .create_provider("Provider")
            .create_pact
            .create_consumer_version("1.2.3")
            .create_consumer_version_tag("prod")
            .create_pact
            .create_webhook
            .create_triggered_webhook
            .create_webhook_execution
            .create_verification
        end

        let(:delete_consumer) { subject.delete "Consumer" }
        let(:delete_provider) { subject.delete "Provider" }

        context "deleting a consumer" do
          it "deletes the pacticipant" do
            expect{ delete_consumer }.to change{ PactBroker::Domain::Pacticipant.all.count }.by(-1)
          end

          it "deletes the child versions" do
            expect{ delete_consumer }.to change{ PactBroker::Domain::Version.where(number: "1.2.3").count }.by(-1)
          end

          it "deletes the child tags" do
            expect{ delete_consumer }.to change{ PactBroker::Domain::Tag.where(name: "prod").count }.by(-1)
          end

          it "deletes the webhooks" do
            expect{ delete_consumer }.to change{ PactBroker::Webhooks::Webhook.count }.by(-1)
          end

          it "deletes the triggered webhooks" do
            expect{ delete_consumer }.to change{ PactBroker::Webhooks::TriggeredWebhook.count }.by(-1)
          end

          it "deletes the webhook executions" do
            expect{ delete_consumer }.to change{ PactBroker::Webhooks::Execution.count }.by(-1)
          end

          it "deletes the child pacts" do
            expect{ delete_consumer }.to change{ PactBroker::Pacts::PactPublication.count }.by(-2)
          end

          it "deletes the verifications" do
            expect{ delete_consumer }.to change{ PactBroker::Domain::Verification.count }.by(-1)
          end
        end

        context "deleting a provider" do
          it "deletes the pacticipant" do
            expect{ delete_provider }.to change{ PactBroker::Domain::Pacticipant.all.count }.by(-1)
          end

          it "does not delete any versions" do
            expect{ delete_provider }.to change{ PactBroker::Domain::Version.where(number: "1.2.3").count }.by(0)
          end

          it "deletes the child tags only if there are any" do
            expect{ delete_provider }.to change{ PactBroker::Domain::Tag.where(name: "prod").count }.by(0)
          end

          it "deletes the webhooks" do
            expect{ delete_provider }.to change{ PactBroker::Webhooks::Webhook.count }.by(-1)
          end

          it "deletes the triggered webhooks" do
            expect{ delete_provider }.to change{ PactBroker::Webhooks::TriggeredWebhook.count }.by(-1)
          end

          it "deletes the webhook executions" do
            expect{ delete_provider }.to change{ PactBroker::Webhooks::Execution.count }.by(-1)
          end

          it "deletes the child pacts" do
            expect{ delete_provider }.to change{ PactBroker::Pacts::PactPublication.count }.by(-2)
          end

          it "deletes the verifications" do
            expect{ delete_provider }.to change{ PactBroker::Domain::Verification.count }.by(-1)
          end
        end
      end
    end
  end
end
