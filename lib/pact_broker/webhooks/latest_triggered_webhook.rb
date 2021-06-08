require "pact_broker/webhooks/triggered_webhook"

module PactBroker
  module Webhooks
    class LatestTriggeredWebhook < TriggeredWebhook
      SELF_JOIN = {
        Sequel[:triggered_webhooks][:webhook_uuid] => Sequel[:triggered_webhooks_2][:webhook_uuid],
        Sequel[:triggered_webhooks][:consumer_id] => Sequel[:triggered_webhooks_2][:consumer_id],
        Sequel[:triggered_webhooks][:provider_id] => Sequel[:triggered_webhooks_2][:provider_id],
        Sequel[:triggered_webhooks][:event_name] => Sequel[:triggered_webhooks_2][:event_name]
      }

      set_dataset(
        Sequel::Model.db[:triggered_webhooks]
          .select(Sequel[:triggered_webhooks].*)
          .exclude(Sequel[:triggered_webhooks][:event_name] => nil)
          .left_join(:triggered_webhooks, SELF_JOIN, { table_alias: :triggered_webhooks_2 }) do
            Sequel[:triggered_webhooks_2][:id] > Sequel[:triggered_webhooks][:id]
          end
          .where(Sequel[:triggered_webhooks_2][:id] => nil)
      )
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
