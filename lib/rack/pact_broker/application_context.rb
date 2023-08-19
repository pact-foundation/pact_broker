# Sets the PactBroker::ApplicationContext on the rack env if it is not already set.

module Rack
  module PactBroker
    class ApplicationContext
      def initialize(app, application_context)
        @app = app
        @application_context = application_context
      end

      def call(env)
        @app.call({ "pactbroker.application_context" => @application_context }.merge(env))
      end
    end
  end
end
