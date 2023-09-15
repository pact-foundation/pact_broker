require "pact_broker/verifications/sequence"

module PactBroker
  module Verifications
    describe Sequence do
      describe "#next_val", migration: true do
        context "for proper databases with proper sequences", skip: !::PactBroker::TestDatabase.postgres? do
          it "increments the value each time" do
            PactBroker::TestDatabase.migrate
            expect(Sequence.next_val).to eq 200
            expect(Sequence.next_val).to eq 201
          end

          it "can rollback without duplicating a sequence number" do
            PactBroker::TestDatabase.migrate
            row = database.from(:verification_sequence_number).select(:value).limit(1).first
            expect(row[:value]).to eq 100
            Sequence.next_val
            PactBroker::TestDatabase.migrate(20201006)
            row = database.from(:verification_sequence_number).select(:value).limit(1).first
            expect(row[:value]).to eq 301
          end

          it "can deal with there not being an existing value in the verification_sequence_number table" do
            PactBroker::TestDatabase.migrate(20201006)
            database.from(:verification_sequence_number).delete
            PactBroker::TestDatabase.migrate
            expect(Sequence.next_val).to eq 1
          end
        end

        context "for databases without sequences", skip: ::PactBroker::TestDatabase.postgres? do
          before do
            PactBroker::TestDatabase.migrate
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
              td.create_pact_with_hierarchy("A", "1", "B")
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
end
