# Mock out the rack.after_reply functionality provided by Puma
# I'm not sure if this is meant to be a public feature or not, but
# there are several mentions of it on the net, so I assume it's ok to use it.
# Puma itself uses the rack.after_reply for http request logging.
#
# See https://github.com/puma/puma/search?q=rack.after_reply
# This middleware executes the hooks that would normally run after the request
# *before* the request ends, for the purposes of testing.

module PactBroker
  module Middleware
    class MockPuma

      def initialize(app)
        @app = app
      end

      def call(env)
        after_reply = []
        response = @app.call({ "rack.after_reply" => after_reply }.merge(env))
        after_reply.each(&:call)
        response
      end
    end
  end
end
