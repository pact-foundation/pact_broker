require_relative 'base_decorator'
require 'pact_broker/api/decorators/webhook_request_decorator'
require 'pact_broker/api/decorators/timestamps'
require 'pact_broker/domain/webhook_request'
require 'pact_broker/api/decorators/basic_pacticipant_decorator'

module PactBroker
  module Api
    module Decorators
      class WebhookDecorator < BaseDecorator

        property :request, :class => PactBroker::Domain::WebhookRequest, :extend => WebhookRequestDecorator

        include Timestamps

        property :consumer, :extend => PactBroker::Api::Decorators::BasicPacticipantDecorator, :embedded => true, writeable: false
        property :provider, :extend => PactBroker::Api::Decorators::BasicPacticipantDecorator, :embedded => true, writeable: false

        link :self do | options |
          {
            title: represented.description,
            href: webhook_url(represented.uuid, options[:base_url])
          }

        end

        link :'pb:pact-webhooks' do | options |
          {
            title: "All webhooks for the pact between #{represented.consumer.name} and #{represented.provider.name}",
            href: webhooks_for_pact_url(represented.consumer, represented.provider, options[:base_url])
          }
        end

        link :'pb:webhooks' do | options |
          {
            title: "All webhooks",
            href: webhooks_url(options[:base_url])
          }
        end

        link :'pb:execute' do | options |
          {
            title: "Test the execution of the webhook by sending a POST request to this URL",
            href: webhook_execution_url(represented, options[:base_url])
          }
        end
      end
    end
  end
end