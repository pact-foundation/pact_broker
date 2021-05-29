require 'pact_broker/diagnostic/resources/heartbeat'
require 'pact_broker/diagnostic/resources/dependencies'
require 'webmachine/adapters/rack_mapped'

module PactBroker
  module Diagnostic

    class App
      def initialize
        @app = build_diagnostic_app
      end

      def call env
        if env['PATH_INFO'].start_with? "/diagnostic/"
          @app.call(env)
        else
          [404, {}, []]
        end
      end

      def build_diagnostic_app
        app = Webmachine::Application.new do |webmachine_app|
          webmachine_app.routes do
            add ['diagnostic','status','heartbeat'], Diagnostic::Resources::Heartbeat, {resource_name: 'diagnostic_heartbeat'}
            add ['diagnostic','status','dependencies'], Diagnostic::Resources::Dependencies, {resource_name: 'diagnostic_dependencies'}
          end
        end

        app.configure do |config|
          config.adapter = :RackMapped
        end

        app.adapter
      end
    end
  end
end
