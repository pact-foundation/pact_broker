module Rack
  module PactBroker
    class SetBaseUrl
      def initialize app, base_url
        @app = app
        @base_url = base_url
      end

      def call env
        if env["pactbroker.base_url"]
          app.call(env)
        else
          app.call(env.merge("pactbroker.base_url" => base_url))
        end
      end

      private

      attr_reader :app, :base_url
    end
  end
end
