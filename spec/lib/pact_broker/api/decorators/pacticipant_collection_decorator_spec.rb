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
            expect(subject[:pacticipants]).to be_instance_of(Array)
            expect(subject[:pacticipants].size).to eq 1
          end
        end

      end
    end
  end
end
