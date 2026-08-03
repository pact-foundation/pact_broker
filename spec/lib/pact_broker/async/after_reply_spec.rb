require "pact_broker/async/after_reply"

module PactBroker
  module Async
    describe AfterReply do
      let(:database_connector) { ->(& block) { block.call } }
      let(:block_result) { [] }
      let(:work) { -> { block_result << :executed } }

      describe "#execute" do
        context "when rack_after_reply is an Array (Puma)" do
          let(:rack_after_reply) { [] }

          subject { AfterReply.new(rack_after_reply: rack_after_reply, database_connector: database_connector) }

          it "appends a lambda to rack_after_reply without executing it immediately" do
            subject.execute(&work)
            expect(block_result).to be_empty
          end

          it "executes the block when the deferred lambda is called" do
            subject.execute(&work)
            rack_after_reply.first.call
            expect(block_result).to eq [:executed]
          end

          it "wraps the block in the database connector" do
            connected = []
            dc = ->(& b) { connected << :connected; b.call }
            AfterReply.new(rack_after_reply: rack_after_reply, database_connector: dc).execute(&work)
            rack_after_reply.first.call
            expect(connected).to eq [:connected]
          end
        end

        context "when rack_after_reply is not an Array (non-Puma server)" do
          let(:rack_after_reply) { nil }

          subject { AfterReply.new(rack_after_reply: rack_after_reply, database_connector: database_connector) }

          it "executes the block synchronously" do
            subject.execute(&work)
            expect(block_result).to eq [:executed]
          end

          it "wraps the block in the database connector" do
            connected = []
            dc = ->(& b) { connected << :connected; b.call }
            AfterReply.new(rack_after_reply: rack_after_reply, database_connector: dc).execute(&work)
            expect(connected).to eq [:connected]
          end
        end
      end
    end
  end
end
