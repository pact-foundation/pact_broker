require_relative 'base_decorator'
require 'pact_broker/api/decorators/webhook_request_decorator'
require 'pact_broker/models/webhook_request'
require 'pact_broker/api/decorators/basic_pacticipant_decorator'

module PactBroker
  module Api
    module Decorators
      class WebhookDecorator < BaseDecorator

        property :request, :class => PactBroker::Models::WebhookRequest, :extend => WebhookRequestDecorator

        property :consumer, :extend => PactBroker::Api::Decorators::BasicPacticipantRepresenter, :embedded => true, writeable: false
        property :provider, :extend => PactBroker::Api::Decorators::BasicPacticipantRepresenter, :embedded => true, writeable: false

        link :self do | options |
          webhook_url(represented, options[:base_url])
        end

      end
    end
  end
end