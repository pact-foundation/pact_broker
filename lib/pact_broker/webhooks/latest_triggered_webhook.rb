require 'pact_broker/webhooks/triggered_webhook'

module PactBroker
  module Webhooks
    class LatestTriggeredWebhook < TriggeredWebhook
      set_dataset(:latest_triggered_webhooks)
    end
  end
end
