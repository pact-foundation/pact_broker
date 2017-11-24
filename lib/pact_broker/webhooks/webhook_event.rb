require 'sequel'
require 'pact_broker/repositories/helpers'

module PactBroker
  module Webhooks
    class WebhookEvent < Sequel::Model

      CONTRACT_CONTENT_CHANGED = 'contract_content_changed'
      CONTRACT_VERIFIABLE_CONTENT_CHANGED = 'contract_verifiable_content_changed'
      VERIFICATION_PUBLISHED = 'verification_published'
      VERIFICATION_STATUS_CHANGED = 'verification_status_changed'
      DEFAULT_EVENT_NAME = CONTRACT_CONTENT_CHANGED

      dataset_module do
        include PactBroker::Repositories::Helpers
      end

    end

    WebhookEvent.plugin :timestamps, update_on_create: true
  end
end
