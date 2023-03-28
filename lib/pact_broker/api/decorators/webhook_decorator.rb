require_relative "base_decorator"
require "pact_broker/domain/webhook_pacticipant"
require "pact_broker/api/decorators/webhook_request_template_decorator"
require "pact_broker/api/decorators/timestamps"
require "pact_broker/webhooks/webhook_request_template"
require "pact_broker/webhooks/webhook_event"
require "pact_broker/api/decorators/basic_pacticipant_decorator"
require_relative "pact_pacticipant_decorator"
require_relative "pacticipant_decorator"

module PactBroker
  module Api
    module Decorators
      class WebhookDecorator < BaseDecorator
        class WebhookEventDecorator < BaseDecorator
          property :name
        end

        property :uuid

        property :description, getter: lambda { |represented:, **| represented.display_description }

        property :consumer, class: Domain::WebhookPacticipant, default: nil do
          property :name
          property :label
        end

        property :provider, class: Domain::WebhookPacticipant, default: nil do
          property :name
          property :label
        end

        property :enabled, default: true

        property :request, :class => PactBroker::Webhooks::WebhookRequestTemplate, extend: WebhookRequestTemplateDecorator
        collection :events, :class => PactBroker::Webhooks::WebhookEvent, extend: WebhookEventDecorator

        include Timestamps

        link :self do | options |
          {
            title: represented.display_description,
            href: webhook_url(represented.uuid, options[:base_url])
          }
        end

        link :'pb:execute' do | options |
          {
            title: "Test the execution of the webhook with the latest matching pact or verification by sending a POST request to this URL",
            href: webhook_execution_url(represented, options[:base_url])
          }
        end

        link :'pb:consumer' do | options |
          if represented.consumer&.name
            {
              title: "Consumer",
              name: represented.consumer.name,
              href: pacticipant_url(options.fetch(:base_url), represented.consumer)
            }
          end
        end

        link :'pb:consumers' do | options |
          if represented.consumer&.label
            {
              title: "Consumers by label",
              name: represented.consumer.label,
              href: pacticipants_with_label_url(options.fetch(:base_url), represented.consumer.label)
            }
          end
        end

        link :'pb:provider' do | options |
          if represented.provider&.name
            {
              title: "Provider",
              name: represented.provider.name,
              href: pacticipant_url(options.fetch(:base_url), represented.provider)
            }
          end
        end

        link :'pb:providers' do | options |
          if represented.provider&.label
            {
              title: "Providers by label",
              name: represented.provider.label,
              href: pacticipants_with_label_url(options.fetch(:base_url), represented.provider.label)
            }
          end
        end

        link :'pb:pact-webhooks' do | options |
          if represented.consumer && represented.provider
            {
              title: "All webhooks for consumer #{represented.consumer.name} and provider #{represented.provider.name}",
              href: webhooks_for_consumer_and_provider_url(represented.consumer, represented.provider, options[:base_url])
            }
          end
        end

        link :'pb:webhooks' do | options |
          {
            title: "All webhooks",
            href: webhooks_url(options[:base_url])
          }
        end

        def from_json(represented)
          super.tap do | webhook |
            if webhook.events == nil
              webhook.events = [PactBroker::Webhooks::WebhookEvent.new(name: PactBroker::Webhooks::WebhookEvent::DEFAULT_EVENT_NAME)]
            end
          end
        end
      end
    end
  end
end
