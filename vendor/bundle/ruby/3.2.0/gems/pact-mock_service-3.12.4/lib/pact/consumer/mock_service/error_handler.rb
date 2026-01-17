module Pact
  module Consumer
    class MockService
      class ErrorHandler

        def initialize app, logger
          @app = app
          @logger = logger
        end

        def call env
          begin
            @app.call(env)
          rescue Pact::Error => e
            @logger.error e.message
            [500, {'Content-Type' => 'application/json'}, [{message: e.message}.to_json]]
          rescue StandardError => e
            message = "Error ocurred in mock service: #{e.class} - #{e.message}"
            @logger.error message
            @logger.error e.backtrace.join("\n")
            [500, {'Content-Type' => 'application/json'}, [{message: message, backtrace: e.backtrace}.to_json]]
          end
        end

        def shutdown
          @app.shutdown
        end
      end
    end
  end
end
