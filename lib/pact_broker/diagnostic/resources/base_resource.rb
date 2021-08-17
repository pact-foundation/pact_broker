require "webmachine"
require "pact_broker/api/resources/authentication"

module PactBroker
  module Diagnostic
    module Resources
      class BaseResource < Webmachine::Resource

        include PactBroker::Api::Resources::Authentication

        def is_authorized?(authorization_header)
          authenticated?(self, authorization_header)
        end

        def forbidden?
          return false if PactBroker.configuration.authorize.nil?
          !PactBroker.configuration.authorize.call(self, {})
        end

        def base_url
          request.env["pactbroker.base_url"] || request.base_uri.to_s.chomp("/")
        end
      end
    end
  end
end
