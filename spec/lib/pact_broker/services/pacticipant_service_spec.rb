require 'spec_helper'
require 'pact_broker/services/pacticipant_service'
require 'pact_broker/models/tag'
require 'pact_broker/models/pact'


module PactBroker

  module Services
    describe PacticipantService do

      subject{ PacticipantService }

      describe ".messages_for_potential_duplicate_pacticipants" do

        let(:base_url) { 'http://example.org' }
        let(:fred_duplicates) { [double('Fred pacticipant')] }
        let(:mary_dulicates) { [double('Mary pacticipant')] }

        before do
          allow(PacticipantService).to receive(:find_potential_duplicate_pacticipants).with("Fred").and_return(fred_duplicates)
          allow(PacticipantService).to receive(:find_potential_duplicate_pacticipants).with("Mary").and_return(mary_dulicates)
          allow(Messages).to receive(:potential_duplicate_pacticipant_message).and_return("message1", "message2")
        end

        subject { PacticipantService.messages_for_potential_duplicate_pacticipants ["Fred", "Mary"], base_url }

        it "finds the potential duplicates for each name" do
          expect(PacticipantService).to receive(:find_potential_duplicate_pacticipants).with("Fred")
          expect(PacticipantService).to receive(:find_potential_duplicate_pacticipants).with("Mary")
          subject
        end

        context "when there are potential duplicates" do

          it "creates a message for each dupliate" do
            expect(Messages).to receive(:potential_duplicate_pacticipant_message).with("Fred", fred_duplicates, base_url)
            expect(Messages).to receive(:potential_duplicate_pacticipant_message).with("Mary", mary_dulicates, base_url)
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
        let(:pacticipant_name) { 'pacticipant_name' }
        let(:duplicates) { ["Fred", "Mary"] }
        let(:pacticipant_names) { double("pacticipant_names") }
        let(:fred) { double('fred pacticipant')}
        let(:mary) { double('mary pacticipant')}
        let(:pacticipant_repository) { instance_double(PactBroker::Repositories::PacticipantRepository)}

        before do
          allow(PactBroker::Functions::FindPotentialDuplicatePacticipantNames).to receive(:call).and_return(duplicates)
          allow(PactBroker::Repositories::PacticipantRepository).to receive(:new).and_return(pacticipant_repository)
          allow(pacticipant_repository).to receive(:pacticipant_names).and_return(pacticipant_names)
          allow(pacticipant_repository).to receive(:find_by_name).with("Fred").and_return(fred)
          allow(pacticipant_repository).to receive(:find_by_name).with("Mary").and_return(mary)
        end

        it "finds all the pacticipant names" do
          expect(pacticipant_repository).to receive(:pacticipant_names)
          subject.find_potential_duplicate_pacticipants pacticipant_name
        end

        it "calculates the duplicates" do
          expect(PactBroker::Functions::FindPotentialDuplicatePacticipantNames).to receive(:call).with(pacticipant_name, pacticipant_names)
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
      end

      describe ".find_relationships" do

        let(:consumer) { instance_double("PactBroker::Models::Pacticpant")}
        let(:provider) { instance_double("PactBroker::Models::Pacticpant")}
        let(:pact) { instance_double("PactBroker::Models::Pact", consumer: consumer, provider: provider)}
        let(:pacts) { [pact]}

        before do
          allow_any_instance_of(PactBroker::Repositories::PactRepository).to receive(:find_latest_pacts).and_return(pacts)
        end

        it "returns a list of relationships" do
          expect(subject.find_relationships).to eq([PactBroker::Models::Relationship.create(consumer, provider)])
        end

      end

      describe "delete" do

        before do
          ProviderStateBuilder.new
            .create_consumer("Consumer")
            .create_consumer_version("2.3.4")
            .create_provider("Provider")
            .create_pact
            .create_consumer_version("1.2.3")
            .create_consumer_version_tag("prod")
            .create_pact
            .create_webhook
        end

        let(:delete_pacticipant) { subject.delete "Consumer" }

        it "deletes the pacticipant" do
          expect{ delete_pacticipant }.to change{
              PactBroker::Models::Pacticipant.all.count
            }.by(-1)
        end

        it "deletes the child versions" do
          expect{ delete_pacticipant }.to change{
            PactBroker::Models::Version.where(number: "1.2.3").count
            }.by(-1)
        end

        it "deletes the child tags" do
          expect{ delete_pacticipant }.to change{
            PactBroker::Models::Tag.where(name: "prod").count
            }.by(-1)
        end

        it "deletes the webhooks" do
          expect{ delete_pacticipant }.to change{
            PactBroker::Repositories::Webhook.count
            }.by(-1)
        end

        it "deletes the child pacts" do
          expect{ delete_pacticipant }.to change{
            PactBroker::Models::Pact.count
            }.by(-2)
        end
      end

    end
  end
end