require 'spec_helper'
require 'pact_broker/repositories/pacticipant_repository'
require 'support/provider_state_builder'

module PactBroker
  module Repositories
    describe PacticipantRepository do


      describe "#pacticipant_names" do

        before do
          ProviderStateBuilder.new
            .create_pacticipant("Plants")
            .create_pacticipant("Animals")
        end

        subject { PacticipantRepository.new.pacticipant_names }

        it "returns an array of pacticipant names" do
          expect(subject).to eq ["Animals", "Plants"]
        end

      end


    end
  end
end
