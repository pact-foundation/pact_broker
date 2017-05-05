require 'pact_broker/configuration'

module PactBroker
  class Configuration

    class ConfigurableBasicAuth

      def initialize(app)
        @app = app
        @predicates = []
      end

      def protect credentials_list, &predicate
        basic_auth_proxy = ::Rack::Auth::Basic.new(app) do | username, password |
          credentials_list.any? do | credentials |
            username == credentials[:username] && password == credentials[:password]
          end
        end
        predicates << [predicate, basic_auth_proxy]
      end

      def call(env)
        predicates = matching_predicates(env)
        if predicates.any?
          cascade(predicates, env)
        else
          app.call(env)
        end
      end

      private

      attr_accessor :app, :predicates

      def matching_predicates env
        predicates.select do | predicate, basic_auth_proxy |
          predicate.call(env)
        end
      end

      def cascade predicates, env
        response = nil
        predicates.each do | predicate, basic_auth_proxy |
          response = basic_auth_proxy.call(env)
          return response if response.first != 401
        end
        response
      end

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
          credentials = configuration.basic_auth_credentials_list_for(scope)
          basic_auth_proxy.protect(credentials, &predicate)
        end
      end
    end
  end
end
