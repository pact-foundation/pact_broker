require 'spec_helper'
require 'pact_broker/functions/find_potential_duplicate_pacticipant_names'

module PactBroker

  module Functions

    describe FindPotentialDuplicatePacticipantNames do

      describe ".call" do

        subject { FindPotentialDuplicatePacticipantNames.call(new_name, existing_names) }

        context "when an existing name exactly equals the new name" do
          let(:new_name) { 'Contracts Service' }
          let(:existing_names) { ['Contracts Service', 'Contracts', 'Something'] }

          it "does not return any potential duplicate names" do
            expect(subject).to eq []
          end
        end

        context "when an existing name mostly includes the new name" do
          let(:new_name) { 'Contracts' }
          let(:existing_names) { ['Contract Service', 'Contacts', 'Something'] }

          it "returns the existing names that match" do
            expect(subject).to eq ['Contract Service']
          end
        end

        context "when a new name mostly includes an existing name" do
          let(:new_name) { 'Contract Service' }
          let(:existing_names) { ['Contracts', 'Contacts', 'Something'] }

          it "returns the existing names that match" do
            expect(subject).to eq ['Contracts']
          end
        end

        context 'when a new name is the same but a different case' do
          let(:new_name) { 'Contract Service' }
          let(:existing_names) { ['contracts', 'Contacts', 'Something'] }

          it "returns the existing names that match" do
            expect(subject).to eq ['contracts']
          end
        end

        context "when a new name is the same as an existing name but without spaces" do
          let(:new_name) { 'ContractService' }
          let(:existing_names) { ['Contracts Service', 'Contacts', 'Something'] }

          it "returns the existing names that match" do
            expect(subject).to eq ['Contracts Service']
          end
        end

        context "when an existing name is the same as the new name but without spaces" do
          let(:new_name) { 'Contract Service' }
          let(:existing_names) { ['ContractsService', 'Contacts', 'Something'] }

          it "returns the existing names that match" do
            expect(subject).to eq ['ContractsService']
          end
        end

        context "when the new name is similar to an existing but with underscores or dashes instead of spaces" do
          let(:new_name) { 'Contract_Service' }
          let(:existing_names) { ['ContractsService', 'Contracts Service', 'contracts-service', 'Contacts', 'Something'] }

          it "returns the existing names that match" do
            expect(subject).to eq ['ContractsService', 'Contracts Service', 'contracts-service']
          end
        end

      end

    end

  end
end