require_relative 'base_decorator'

module PactBroker
  module Api
    module Decorators
      class WebhookRequestTemplateDecorator < BaseDecorator

        property :method
        property :url
        property :headers, getter: lambda { | _ | headers.empty? ? nil : self.redacted_headers }
        property :body
        property :username
        property :password, getter: lambda { | _ | display_password }


        def redacted_headers
          represented.headers
        end
      end
    end
  end
end