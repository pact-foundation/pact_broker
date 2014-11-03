require 'spec_helper'
require 'pact_broker/api/decorators/pacticipant_decorator'
require 'pact_broker/domain/pacticipant'

module PactBroker

  module Api

    module Decorators

      describe PacticipantRepresenter do

        let(:created_at) { Time.new(2014, 3, 4) }
        let(:updated_at) { Time.new(2014, 3, 5) }
        let(:pacticipant) { PactBroker::Domain::Pacticipant.new(name: 'Name', updated_at: updated_at, created_at: created_at)}

        subject { JSON.parse PacticipantRepresenter.new(pacticipant).to_json, symbolize_names: true }

        it "includes timestamps" do
          expect(subject[:createdAt]).to eq created_at.xmlschema
          expect(subject[:updatedAt]).to eq updated_at.xmlschema
        end
      end
    end
  end
end
