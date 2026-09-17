require "pact_broker/logging/tag_propagation"
require "semantic_logger"

module PactBroker
  module Logging
    describe TagPropagation do
      describe ".capture" do
        it "returns the currently active named tags" do
          SemanticLogger.tagged(request_id: "abc") do
            expect(TagPropagation.capture).to eq(request_id: "abc")
          end
        end

        it "returns an empty hash when nothing is tagged" do
          expect(TagPropagation.capture).to eq({})
        end

        it "returns a snapshot that is unaffected by later tagging" do
          captured = nil
          SemanticLogger.tagged(request_id: "abc") { captured = TagPropagation.capture }

          SemanticLogger.tagged(request_id: "different") do
            expect(captured).to eq(request_id: "abc")
          end
        end
      end

      describe ".with" do
        it "re-establishes the tags for the duration of the block" do
          captured = SemanticLogger.tagged(request_id: "abc") { TagPropagation.capture }

          TagPropagation.with(captured) do
            expect(SemanticLogger.named_tags).to eq(request_id: "abc")
          end
        end

        it "does not leak the tags after the block" do
          TagPropagation.with(request_id: "abc") { nil }

          expect(SemanticLogger.named_tags).to eq({})
        end

        it "returns the block's value" do
          expect(TagPropagation.with(request_id: "abc") { "result" }).to eq "result"
        end

        it "runs the block without tagging when there is nothing to restore" do
          expect(TagPropagation.with({}) { "result" }).to eq "result"
          expect(TagPropagation.with(nil) { "result" }).to eq "result"
        end

        it "works from a different thread, which is the whole point" do
          captured = SemanticLogger.tagged(request_id: "abc") { TagPropagation.capture }

          value = Thread.new do
            TagPropagation.with(captured) { SemanticLogger.named_tags }
          end.value

          expect(value).to eq(request_id: "abc")
        end
      end
    end
  end
end
