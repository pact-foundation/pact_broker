require 'spec_helper'
require 'pact_broker/api/decorators/pacticipant_collection_decorator'

module PactBroker

  module Api

    module Decorators

      describe PacticipantCollectionRepresenter do

        context "with no pacticipants" do
          let(:pacticipants) { [] }

          subject { JSON.parse PacticipantCollectionRepresenter.new(pacticipants).to_json, symbolize_names: true }

          it "doesn't blow up" do
            subject
          end

        end

      end
    end
  end
end