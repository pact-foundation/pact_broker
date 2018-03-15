require 'pact_broker/verifications/sequence'

module PactBroker
  module Verifications
    describe Sequence do
      describe "#next_val", migration: true do

        before do
          PactBroker::Database.migrate
        end

        context "when there is a row in the verification_sequence_number table" do
          before do
            Sequence.select_all.delete
            Sequence.insert(value: 1)
          end

          it "increments the value and returns it" do
            expect(Sequence.next_val).to eq 2
          end
        end

        context "when there is no row in the verification_sequence_number table and no existing verifications" do
          before do
            Sequence.select_all.delete
          end

          it "inserts and returns the value 1" do
            expect(Sequence.next_val).to eq 1
          end
        end

        context "when there is no row in the verification_sequence_number table and there are existing verifications" do
          before do
            Sequence.select_all.delete
            TestDataBuilder.new.create_pact_with_hierarchy("A", "1", "B")
              .create_verification(provider_version: "2")
          end

          it "inserts a number that is guaranteed to be higher than any of the existing verification numbers from when we tried to do this without a sequence" do
            expect(Sequence.next_val).to eq 101
          end
        end
      end
    end
  end
end
