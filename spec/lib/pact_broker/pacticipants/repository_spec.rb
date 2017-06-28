require 'spec_helper'
require 'pact_broker/pacticipants/repository'
require 'support/test_data_builder'

module PactBroker
  module Pacticipants
    describe Repository do

      describe "#find_by_name" do
        before do
          TestDataBuilder.new.create_pacticipant("Foo Bar")
        end

        subject { Repository.new.find_by_name('foo bar') }

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
          TestDataBuilder.new
            .create_pacticipant("Plants")
            .create_pacticipant("Animals")
        end

        subject { Repository.new.pacticipant_names }

        it "returns an array of pacticipant names" do
          expect(subject).to eq ["Animals", "Plants"]
        end

      end

      describe "#find_all_pacticipant_versions_in_reverse_order" do
        before do
          TestDataBuilder.new
            .create_consumer("Foo")
            .create_consumer_version("1.2.3")
            .create_consumer_version("4.5.6")
            .create_consumer("Bar")
            .create_consumer_version("8.9.0")
        end

        subject { Repository.new.find_all_pacticipant_versions_in_reverse_order "Foo" }

        it "returns all the application versions for the given consumer" do
          expect(subject.collect(&:number)).to eq ["4.5.6", "1.2.3"]
        end
      end

    end
  end
end
