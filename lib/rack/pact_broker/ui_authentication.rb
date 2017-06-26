require 'pact_broker/api/resources/authentication'

module Rack
  module PactBroker
    class UIAuthentication

      include ::PactBroker::Api::Resources::Authentication

      def initialize app
        @app = app
      end

      def call env
        if auth? env
          @app.call(env)
        else
          [401, {'WWW-Authenticate' => 'Basic realm="Restricted Area"'}, []]
        end
      end

      def auth? env
        authenticated? nil, env['HTTP_AUTHORIZATION']
      end
    end
  end
end
