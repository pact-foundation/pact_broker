require 'spec_helper'
require 'pact_broker/api/decorators/pacticipant_collection_decorator'
require 'pact_broker/domain/pacticipant'

module PactBroker
  module Api
    module Decorators

      describe PacticipantCollectionDecorator do
        subject { JSON.parse PacticipantCollectionDecorator.new(pacticipants).to_json, symbolize_names: true }

        context "with no pacticipants" do
          let(:pacticipants) { [] }

          it "doesn't blow up" do
            subject
          end
        end

        context "with pacticipants" do
          let(:pacticipant) { PactBroker::Domain::Pacticipant.new(name: 'Name', created_at: DateTime.new, updated_at: DateTime.new)}
          let(:pacticipants) { [pacticipant] }

          it "displays a list of pacticipants" do
            expect(subject[:_embedded][:pacticipants]).to be_instance_of(Array)
            expect(subject[:_embedded][:pacticipants].size).to eq 1
          end
        end
      end

      describe DeprecatedPacticipantCollectionDecorator do
        let(:pacticipant) { PactBroker::Domain::Pacticipant.new(name: 'Name', created_at: DateTime.new, updated_at: DateTime.new)}
        let(:pacticipants) { [pacticipant] }

        subject { JSON.parse DeprecatedPacticipantCollectionDecorator.new(pacticipants).to_json, symbolize_names: true }

        it "doesn't put the pacticipants under the _embedded key" do
          expect(subject).to_not have_key(:_embedded)
        end

        it "puts the pacticipants under the pacticipants key" do
          expect(subject[:pacticipants]).to be_instance_of(Array)
        end
      end
    end
  end
end
