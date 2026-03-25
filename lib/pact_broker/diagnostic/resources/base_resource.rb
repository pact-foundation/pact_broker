require "webmachine"

module PactBroker
  module Diagnostic
    module Resources
      class BaseResource < Webmachine::Resource

        include PactBroker::Api::Resources::Authentication

        def is_authorized?(authorization_header)
          authenticated?(self, authorization_header)
        end

        def forbidden?
          return false unless PactBroker::Configuration.configuration.authorization_configured?
          !PactBroker::Configuration.configuration.authorize.call(self, {})
        end

        def base_url
          request.env["pactbroker.base_url"] || request.base_uri.to_s.chomp("/")
        end
      end
    end
  end
end
