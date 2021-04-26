module Rack
  module PactBroker
    class Convert404ToHal

      def initialize app
        @app = app
      end

      def call env
        response = @app.call(env)

        if response.first == 404 && response[1]['Content-Type'] == 'text/html' && !(env['HTTP_ACCEPT'] =~ /html|javascript|css/)
          [404, { 'Content-Type' => 'application/hal+json;charset=utf-8'},[]]
        else
          response
        end
      end
    end
  end
end
