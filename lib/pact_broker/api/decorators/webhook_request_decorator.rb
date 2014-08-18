require_relative 'base_decorator'

module PactBroker
  module Api
    module Decorators
      class WebhookRequestDecorator < BaseDecorator

        property :method
        property :url
        property :headers, getter: lambda { | _ | headers.empty? ? nil : headers }
        property :body
        property :username
        property :password, getter: lambda { | _ | password.nil? ? nil : "*****" }

      end
    end
  end
end