require "pact_broker/webhooks/triggered_webhook"

module PactBroker
  module Webhooks
    class LatestTriggeredWebhook < TriggeredWebhook
      set_dataset(:latest_triggered_webhooks)
    end
  end
end

# Table: latest_triggered_webhooks
# Columns:
#  id                  | integer                     |
#  trigger_uuid        | text                        |
#  trigger_type        | text                        |
#  pact_publication_id | integer                     |
#  webhook_id          | integer                     |
#  webhook_uuid        | text                        |
#  consumer_id         | integer                     |
#  provider_id         | integer                     |
#  status              | text                        |
#  created_at          | timestamp without time zone |
#  updated_at          | timestamp without time zone |
#  verification_id     | integer                     |
#  event_name          | text                        |
