# Saves a block for execution after the HTTP response has been sent to the user.
# When the block is executed, it connects to the database before executing the code.
# This is good for doing things that might take a while and don't have to be done before
# the response is sent, and don't need retries (in which case, it might be better to use a SuckerPunch Job).
#
# This leverages a feature of Puma which I'm not sure is meant to be public or not.
# There are serveral mentions of it on the internet, so I assume it's ok to use it.
# Puma itself uses the rack.after_reply for http request logging.
#
# https://github.com/search?q=repo%3Apuma%2Fpuma%20rack.after_reply&type=code

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
