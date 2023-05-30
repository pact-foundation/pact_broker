require "pact_broker/logging"

# Allows the load-time configuration to be overridden on a per-request basis (for Pactflow)

module PactBroker
  module Api
    module Middleware
      class Configuration
        include PactBroker::Logging

        def initialize(app, configuration)
          @app = app
          @configuration = configuration
        end

        def call(env)
          if (overrides = env["pactbroker.configuration_overrides"])&.any?
            dupped_configuration = configuration.dup
            dupped_configuration.override_runtime_configuration!(overrides)
            dupped_configuration.freeze
            PactBroker.set_configuration(dupped_configuration)
            app.call(env)
          else
            PactBroker.set_configuration(configuration)
            app.call(env)
          end
        end

        private

        attr_reader :app, :configuration
      end
    end
  end
end
