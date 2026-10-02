require "pact_broker/async/after_reply"
require "semantic_logger"

module PactBroker
  module Async
    describe AfterReply do
      let(:database_connector) { ->(&block) { block.call } }
      let(:rack_env) do
        {
          "pactbroker.database_connector" => database_connector,
          "rack.after_reply" => []
        }
      end

      it "runs the block with the database connector" do
        called = false
        AfterReply.new(rack_env).execute { called = true }

        rack_env["rack.after_reply"].each(&:call)

        expect(called).to be true
      end

      it "restores the logging tags that were active when the block was registered" do
        tags_inside_callback = nil

        SemanticLogger.tagged(request_id: "abc") do
          AfterReply.new(rack_env).execute { tags_inside_callback = SemanticLogger.named_tags }
        end

        # The callback runs after the request, so outside the tagged block.
        expect(SemanticLogger.named_tags).to eq({})
        rack_env["rack.after_reply"].each(&:call)

        expect(tags_inside_callback).to eq(request_id: "abc")
      end
    end
  end
end
