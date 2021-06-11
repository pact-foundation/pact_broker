module Rack
  module PactBroker
    class NoAuth
      def initialize app, *_args
        @app = app
      end

      def call(env)
        @app.call(env)
      end
    end
  end
end
