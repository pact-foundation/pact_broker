require "pact_broker/async/after_reply"

module PactBroker
  module Api
    module Resources
      module AfterReply

        # @param [Callable] block the block to execute after the response has been sent to the user.
        def after_reply(&block)
          PactBroker::Async::AfterReply.new(
            rack_after_reply: request.env["rack.after_reply"],
            database_connector: request.env["pactbroker.database_connector"]
          ).execute(&block)
        end
      end
    end
  end
end
