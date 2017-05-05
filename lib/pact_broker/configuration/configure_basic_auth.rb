require 'pact_broker/configuration'

module PactBroker
  class Configuration

    class ConfigurableBasicAuth

      def initialize(app)
        @app = app
        @predicates = []
      end

      def protect credentials, &predicate
        basic_auth_proxy = ::Rack::Auth::Basic.new(app) do | username, password |
          username = credentials[:username] && password == credentials[:password]
        end
        predicates << [predicate, basic_auth_proxy]
      end

      def call(env)
        predicates.each do | predicate, auth_proxy |
          if predicate.call(env)
            return auth_proxy.call(env)
          end
        end
        app.call(env)
      end

      private

      attr_accessor :app, :predicates

    end

    class ConfigureBasicAuth

      def self.call app, configuration
        new(app, configuration).call
      end

      def initialize app, configuration
        @configuration = configuration
        @basic_auth_proxy = ConfigurableBasicAuth.new(app)
      end

      def call
        configuration.basic_auth_predicates.each do | scope, predicate |
          configure_basic_auth_for_scope scope, &predicate
        end

        basic_auth_proxy
      end

      private

      attr_accessor :basic_auth_proxy, :configuration

      def configure_basic_auth_for_scope scope, &predicate
        if configuration.protect_with_basic_auth?(scope)
          credentials = configuration.basic_auth_credentials_for(scope)
          basic_auth_proxy.protect(credentials, &predicate)
        end
      end
    end
  end
end
