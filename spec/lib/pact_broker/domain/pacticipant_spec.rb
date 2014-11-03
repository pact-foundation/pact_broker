require 'spec_helper'
require 'pact_broker/domain/pacticipant'

module PactBroker

  module Domain

    describe Pacticipant do

      describe "validate" do

        context "with all valid attributes" do
          subject { Pacticipant.new name: 'Name' }

          it "returns an empty array" do
            expect(subject.validate).to eq []
          end
        end

        context "with no name" do
          subject { Pacticipant.new }

          it "returns an error" do
            expect(subject.validate).to eq ["Missing required attribute 'name'"]
          end
        end
      end

    end

  end
end