require 'sequel'
require 'pact_broker/domain/webhook'
require 'pact_broker/webhooks/webhook_request_template'
require 'pact_broker/domain/pacticipant'

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
        include PactBroker::Repositories::Helpers

        def enabled
          where(enabled: true)
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
          consumer: consumer,
          provider: provider,
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
        (consumer_id == integration.consumer_id || !consumer_id) && (provider_id == integration.provider_id || !provider_id)
      end

      private

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
          headers: webhook.request.headers
        }
      end
    end
  end
end

# Table: webhooks
# Columns:
#  id                   | integer                     | PRIMARY KEY DEFAULT nextval('webhooks_id_seq'::regclass)
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
# Indexes:
#  webhooks_pkey   | PRIMARY KEY btree (id)
#  uq_webhook_uuid | UNIQUE btree (uuid)
# Foreign key constraints:
#  fk_webhooks_consumer | (consumer_id) REFERENCES pacticipants(id)
#  fk_webhooks_provider | (provider_id) REFERENCES pacticipants(id)
# Referenced By:
#  webhook_headers    | fk_webhookheaders_webhooks         | (webhook_id) REFERENCES webhooks(id)
#  webhook_executions | webhook_executions_webhook_id_fkey | (webhook_id) REFERENCES webhooks(id)
#  triggered_webhooks | triggered_webhooks_webhook_id_fkey | (webhook_id) REFERENCES webhooks(id)
#  webhook_events     | webhook_events_webhook_id_fkey     | (webhook_id) REFERENCES webhooks(id) ON DELETE CASCADE
