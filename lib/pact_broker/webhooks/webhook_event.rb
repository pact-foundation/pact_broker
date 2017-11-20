require 'sequel'
require 'pact_broker/repositories/helpers'

module PactBroker
  module Webhooks
    class WebhookEvent < Sequel::Model

      DEFAULT_EVENT_NAME = 'contract_changed'

      dataset_module do
        include PactBroker::Repositories::Helpers
      end

    end

    WebhookEvent.plugin :timestamps, update_on_create: true
  end
end
