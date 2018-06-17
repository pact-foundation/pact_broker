require 'sequel'
require 'pact_broker/repositories/helpers'

module PactBroker
  module Webhooks
    class WebhookEvent < Sequel::Model

      CONTRACT_CONTENT_CHANGED = 'contract_content_changed'
      VERIFICATION_PUBLISHED = 'provider_verification_published'
      DEFAULT_EVENT_NAME = CONTRACT_CONTENT_CHANGED
      #CONTRACT_VERIFIABLE_CONTENT_CHANGED = 'contract_verifiable_content_changed'
      #VERIFICATION_STATUS_CHANGED = 'verification_status_changed'

      EVENT_NAMES = [CONTRACT_CONTENT_CHANGED, VERIFICATION_PUBLISHED]

      dataset_module do
        include PactBroker::Repositories::Helpers
      end

      def contract_content_changed?
        name == CONTRACT_CONTENT_CHANGED
      end

      def provider_verification_published?
        name == VERIFICATION_PUBLISHED
      end

    end

    WebhookEvent.plugin :timestamps, update_on_create: true
  end
end
