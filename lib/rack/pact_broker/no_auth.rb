module Rack
  module PactBroker
    class NoAuth
      def initialize app, *args, &block
        @app = app
      end

      def call(env)
        @app.call(env)
      end
    end
  end
end
