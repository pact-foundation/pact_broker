require_relative 'base_decorator'
require 'pact_broker/api/decorators/webhook_request_decorator'
require 'pact_broker/models/webhook_request'

module PactBroker
  module Api
    module Decorators
      class WebhookDecorator < BaseDecorator

        property :request, :class => PactBroker::Models::WebhookRequest, :extend => WebhookRequestDecorator

        link :self do | options |
          webhook_url(represented, options[:base_url])
        end

      end
    end
  end
end