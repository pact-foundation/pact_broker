module PactBroker
  module Async
    class AfterReply

      def initialize(rack_env)
        @rack_env = rack_env
        @database_connector = rack_env.fetch("pactbroker.database_connector")
      end

      def execute(&block)
        dc = @database_connector
        @rack_env["rack.after_reply"] << lambda {
          dc.call do
            block.call
          end
        }
      end
    end
  end
end
