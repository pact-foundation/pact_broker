require "pact_broker/api/contracts/base_contract"
require "pact_broker/webhooks/webhook_event"
require "pact_broker/api/contracts/validation_helpers"
require "pact_broker/api/contracts/webhook_request_contract"
require "pact_broker/api/contracts/webhook_pacticipant_contract"

module PactBroker
  module Api
    module Contracts
      class WebhookContract < BaseContract
        validation do
          json do
            optional(:consumer).maybe(:hash)
            optional(:provider).maybe(:hash)
            required(:request).filled(:hash)
            optional(:events).maybe(min_size?: 1)
            optional(:enabled).filled(:bool)
          end
        end

        property :consumer do
          property :name
          property :label

          validation(contract: WebhookPacticipantContract.new)
        end

        property :provider do
          property :name
          property :label

          validation(contract: WebhookPacticipantContract.new)
        end

        property :enabled

        property :request do
          property :url
          property :http_method

          validation(contract: WebhookRequestContract.new)
        end

        collection :events do
          property :name

          validation do
            json do
              required(:name).filled(included_in?: PactBroker::Webhooks::WebhookEvent::EVENT_NAMES)
            end
          end
        end
      end
    end
  end
end
