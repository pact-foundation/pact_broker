module PactBroker
  class WebhookEndpointMiddleware
    def initialize app
      @app = app
    end

    def call(env)
      if env['PATH_INFO'] == '/pact-changed-webhook'
        body = env['rack.input'].read
        puts body
        PactBroker::VerificationJob.perform_in(2, JSON.parse(body, symbolize_names: true))
        [200, {}, ["Pact changed webhook executed"]]
      elsif env['PATH_INFO'] == '/verification-published-webhook'
        body = env['rack.input'].read
        puts body
        [200, {}, ["Verification webhook executed"]]
      else
        @app.call(env)
      end
    end
  end
end