require_relative 'base_decorator'

module PactBroker
  module Api
    module Decorators
      class WebhookRequestDecorator < BaseDecorator

          property :method
          property :url
          property :headers
          property :body

      end
    end
  end
end