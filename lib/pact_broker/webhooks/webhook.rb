require "pact_broker/dataset"
require "pact_broker/domain/webhook"
require "pact_broker/webhooks/webhook_request_template"
require "pact_broker/domain/pacticipant"

module PactBroker
  module Webhooks
    class Webhook < Sequel::Model
      set_primary_key :id
      plugin :serialization, :json, :headers
      plugin :timestamps, update_on_create: true

      associate(:many_to_one, :provider, :class => "PactBroker::Domain::Pacticipant", :key => :provider_id, :primary_key => :id)
      associate(:many_to_one, :consumer, :class => "PactBroker::Domain::Pacticipant", :key => :consumer_id, :primary_key => :id)
      one_to_many :events, :class => "PactBroker::Webhooks::WebhookEvent", :reciprocal => :webhook

      dataset_module do
        include PactBroker::Dataset

        # Keep the triggered webhooks after the webhook has been deleted
        def delete
          require "pact_broker/webhooks/triggered_webhook"
          TriggeredWebhook.where(webhook: self).update(webhook_id: nil)
          super
        end

        def for_event_name(event_name)
          join(:webhook_events, { webhook_id: :id })
            .where(Sequel[:webhook_events][:name] => event_name)
        end

        def find_by_consumer_and_or_provider consumer, provider

          where(
            Sequel.|(
              { consumer_id: consumer.id, provider_id: provider.id },
              { consumer_id: nil, provider_id: provider.id, consumer_label: nil },
              { consumer_id: consumer.id, provider_id: nil, provider_label: nil },
              { consumer_id: nil, provider_id: nil, consumer_label: nil, provider_label: nil },
              *labels_criteria_for_consumer_or_provider(consumer, provider)
            )
          )
        end

        def find_by_consumer_and_provider consumer, provider
          criteria = {
            consumer_id: (consumer ? consumer.id : nil),
            provider_id: (provider ? provider.id : nil)
          }
          where(criteria)
        end

        def enabled
          where(enabled: true)
        end

        private

        def labels_criteria_for_consumer_or_provider(consumer, provider)
          consumer_labels = consumer.labels.map(&:name)
          provider_labels = provider.labels.map(&:name)

          [].then do |criteria|
            next criteria if consumer_labels.empty?
            criteria + [
              { consumer_label: consumer_labels, provider_label: nil, provider_id: nil },
              { consumer_label: consumer_labels, provider_label: nil, provider_id: provider.id }
            ]
          end.then do |criteria|
            next criteria if provider_labels.empty?
            criteria + [
              { provider_label: provider_labels, consumer_label: nil, consumer_id: nil },
              { provider_label: provider_labels, consumer_label: nil, consumer_id: consumer.id }
            ]
          end.then do |criteria|
            next criteria if consumer_labels.empty? || provider_labels.empty?
            criteria + [
              { consumer_label: consumer_labels, provider_label: provider_labels }
            ]
          end
        end
      end

      def update_from_domain webhook
        set(self.class.properties_hash_from_domain(webhook))
      end

      def self.from_domain webhook, consumer, provider
        new(
          properties_hash_from_domain(webhook).merge(uuid: webhook.uuid)
        ).tap do | db_webhook |
          db_webhook.consumer_id = consumer.id if consumer
          db_webhook.provider_id = provider.id if provider
        end
      end

      def self.not_plain_text_password password
        password.nil? ? nil : Base64.strict_encode64(password)
      end

      def to_domain
        Domain::Webhook.new(
          uuid: uuid,
          description: description,
          consumer: webhook_consumer,
          provider: webhook_provider,
          events: events,
          request: Webhooks::WebhookRequestTemplate.new(request_attributes),
          enabled: enabled,
          created_at: created_at,
          updated_at: updated_at)
      end

      def request_attributes
        values.merge(headers: headers, body: parsed_body, password: plain_text_password, uuid: uuid)
      end

      def plain_text_password
        password.nil? ? nil : Base64.strict_decode64(password)
      end

      def parsed_body
        if body && is_json_request_body
          JSON.parse(body)
        else
          body
        end
      end

      def is_for? integration
        (
          consumer_id == integration.consumer_id ||
          match_label?(:consumer, integration) ||
          match_all?(:consumer)
        ) && (
          provider_id == integration.provider_id ||
          match_label?(:provider, integration) ||
          match_all?(:provider)
        )
      end

      # Keep the triggered webhooks after the webhook has been deleted
      def delete
        require "pact_broker/webhooks/triggered_webhook"
        TriggeredWebhook.where(webhook_id: id).update(webhook_id: nil)
        super
      end

      def self.properties_hash_from_domain webhook
        is_json_request_body = !(String === webhook.request.body || webhook.request.body.nil?) # Can't rely on people to set content type
        {
          description: webhook.description,
          method: webhook.request.method,
          url: webhook.request.url,
          username: webhook.request.username,
          password: not_plain_text_password(webhook.request.password),
          enabled: webhook.enabled.nil? ? true : webhook.enabled,
          body: (is_json_request_body ? webhook.request.body.to_json : webhook.request.body),
          is_json_request_body: is_json_request_body,
          headers: webhook.request.headers,
          consumer_label: webhook.consumer&.label,
          provider_label: webhook.provider&.label
        }
      end

      def webhook_consumer
        return if consumer.nil? && consumer_label.nil?

        Domain::WebhookPacticipant.new(name: consumer&.name, label: consumer_label)
      end

      def webhook_provider
        return if provider.nil? && provider_label.nil?

        Domain::WebhookPacticipant.new(name: provider&.name, label: provider_label)
      end

      def match_all?(name)
        public_send(:"#{name}_id").nil? && public_send(:"#{name}_label").nil?
      end

      def match_label?(name, integration)
        label = public_send(:"#{name}_label")
        public_send(:"#{name}_id").nil? && integration.public_send(name).label?(label)
      end
    end
  end
end

# Table: webhooks
# Columns:
#  id                   | integer                     | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  uuid                 | text                        | NOT NULL
#  method               | text                        | NOT NULL
#  url                  | text                        | NOT NULL
#  body                 | text                        |
#  is_json_request_body | boolean                     |
#  consumer_id          | integer                     |
#  provider_id          | integer                     |
#  created_at           | timestamp without time zone |
#  updated_at           | timestamp without time zone |
#  username             | text                        |
#  password             | text                        |
#  enabled              | boolean                     | DEFAULT true
#  description          | text                        |
#  headers              | text                        |
#  consumer_label       | text                        |
#  provider_label       | text                        |
# Indexes:
#  webhooks_pkey   | PRIMARY KEY btree (id)
#  uq_webhook_uuid | UNIQUE btree (uuid)
# Check constraints:
#  consumer_label_exclusion | (consumer_id IS NULL OR consumer_id IS NOT NULL AND consumer_label IS NULL)
#  provider_label_exclusion | (provider_id IS NULL OR provider_id IS NOT NULL AND provider_label IS NULL)
# Foreign key constraints:
#  fk_webhooks_consumer | (consumer_id) REFERENCES pacticipants(id)
#  fk_webhooks_provider | (provider_id) REFERENCES pacticipants(id)
# Referenced By:
#  triggered_webhooks | triggered_webhooks_webhook_id_fkey | (webhook_id) REFERENCES webhooks(id)
#  webhook_events     | webhook_events_webhook_id_fkey     | (webhook_id) REFERENCES webhooks(id) ON DELETE CASCADE
#  webhook_executions | webhook_executions_webhook_id_fkey | (webhook_id) REFERENCES webhooks(id)
#  webhook_headers    | fk_webhookheaders_webhooks         | (webhook_id) REFERENCES webhooks(id)
