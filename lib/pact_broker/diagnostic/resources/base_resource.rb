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
      end
    end
  end
end
