require "pact_broker/api/contracts/contract_support"
require "pact_broker/api/contracts/webhook_request_contract"
require "pact_broker/api/contracts/webhook_pacticipant_contract"
require "pact_broker/webhooks/webhook_event"

module PactBroker
  module Api
    module Contracts
      class WebhookContract < Dry::Validation::Contract
        include DryValidationMethods

        UUID_REGEX = /^[A-Za-z0-9_\-]{16,}$/

        class EventContract < Dry::Validation::Contract
          json do
            required(:name).filled(included_in?: PactBroker::Webhooks::WebhookEvent::EVENT_NAMES)
          end
        end

        json do
          optional(:uuid).maybe(:string) # set in resource class from the path info - doesn't come in in the request body
          optional(:consumer).maybe(:hash)
          optional(:provider).maybe(:hash)
          required(:request).filled(:hash)
          optional(:events).maybe(min_size?: 1)
          optional(:enabled).filled(:bool)
        end

        rule(:consumer).validate(validate_with_contract: WebhookPacticipantContract)
        rule(:provider).validate(validate_with_contract: WebhookPacticipantContract)
        rule(:request).validate(validate_with_contract: WebhookRequestContract)
        rule(:events).validate(validate_each_with_contract: EventContract)

        rule(:uuid) do
          if value && !(value =~ UUID_REGEX)
            key.failure(validation_message("invalid_webhook_uuid"))
          end
        end
      end
    end
  end
end
