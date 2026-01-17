module Pact
  module MockService
    module ControlServer
      class RequirePacticipantHeaders

        def initialize app
          @app = app
        end

        def call env
          if env['HTTP_X_PACT_CONSUMER'] && env['HTTP_X_PACT_PROVIDER']
            @app.call(env)
          else
            [500, {}, ["Please specify the consumer name and the provider name by setting the X-Pact-Consumer and X-Pact-Provider headers"]]
          end
        end
      end
    end
  end
end
