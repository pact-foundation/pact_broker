require "webmachine/resource/authentication"

module PactBroker
  module Api
    module Resources
      module Authentication

        include Webmachine::Resource::Authentication

        def authenticated? resource, authorization_header
          return true unless PactBroker::Configuration.configuration.authentication_configured?

          if PactBroker::Configuration.configuration.authenticate
            authorized = PactBroker::Configuration.configuration.authenticate.call(resource, authorization_header, {})
            return true if authorized
          end

          if PactBroker::Configuration.configuration.authenticate_with_basic_auth
            basic_auth(authorization_header, "Pact Broker") do |username, password|
              authorized = PactBroker::Configuration.configuration.authenticate_with_basic_auth.call(resource, username, password, {})
              return true if authorized
            end
          end

          false
        end
      end
    end
  end
end
