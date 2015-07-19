require 'spec_helper'
require 'pact_broker/repositories/pacticipant_repository'
require 'support/provider_state_builder'

module PactBroker
  module Repositories
    describe PacticipantRepository do

      describe "#find_by_name" do
        before do
          ProviderStateBuilder.new.create_pacticipant("Foo Bar")
        end

        subject { PacticipantRepository.new.find_by_name('foo bar') }

        context "when the name is a different case" do
          context "with case sensitivity turned on" do
            before do
              allow(PactBroker.configuration).to receive(:use_case_sensitive_resource_names).and_return(true)
            end

            it "returns nil" do
              expect(subject).to be nil
            end
          end

          context "with case sensitivity turned off" do
            before do
              allow(PactBroker.configuration).to receive(:use_case_sensitive_resource_names).and_return(false)
            end

            it "returns the pacticipant" do
              expect(subject).to_not be nil
              expect(subject.name).to eq "Foo Bar"
            end
          end
        end
      end

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
