require 'ostruct'

module Rack
  module PactBroker
    class ResetThreadData
      def initialize app
        @app = app
      end

      def call env
        data = OpenStruct.new
        Thread.current[:pact_broker_thread_data] ||= data
        response = @app.call(env)
        # only delete it if it's the same object that we set
        if data.equal?(Thread.current[:pact_broker_thread_data])
          Thread.current[:pact_broker_thread_data] = nil
        end
        response
      end
    end
  end
end
