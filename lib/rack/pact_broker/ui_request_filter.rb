# Decides whether this is a request for the UI or a request for the API
# This is only needed so that UI auth logic is not applied to an API request.
# If it was, a 401 or 403 would be returned before the API got a chance
# to actually handle the request, as it would short circuit the cascade
# logic.

require 'rack/pact_broker/request_target'

module Rack
  module PactBroker
    class UIRequestFilter
      include RequestTarget

      def initialize app
        @app = app
      end

      def call env
        if request_for_ui?(env)
          @app.call(env)
        else
          # send the request on to the next app in the Rack::Cascade
          [404, {},[]]
        end
      end
    end
  end
end
