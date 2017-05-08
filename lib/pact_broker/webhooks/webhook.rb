require 'sequel'
require 'pact_broker/domain/webhook'
require 'pact_broker/domain/pacticipant'

module PactBroker
  module Webhooks
    class Webhook < Sequel::Model

      set_primary_key :id
      associate(:many_to_one, :provider, :class => "PactBroker::Domain::Pacticipant", :key => :provider_id, :primary_key => :id)
      associate(:many_to_one, :consumer, :class => "PactBroker::Domain::Pacticipant", :key => :consumer_id, :primary_key => :id)
      one_to_many :headers, :class => "PactBroker::Webhooks::WebhookHeader", :reciprocal => :webhook

      def before_destroy
        WebhookHeader.where(webhook_id: id).destroy
      end

      def self.from_domain webhook, consumer, provider
        is_json_request_body = !(String === webhook.request.body || webhook.request.body.nil?) # Can't rely on people to set content type
        new(
          uuid: webhook.uuid,
          method: webhook.request.method,
          url: webhook.request.url,
          username: webhook.request.username,
          password: not_plain_text_password(webhook.request.password),
          body: (is_json_request_body ? webhook.request.body.to_json : webhook.request.body),
          is_json_request_body: is_json_request_body
        ).tap do | db_webhook |
          db_webhook.consumer_id = consumer.id
          db_webhook.provider_id = provider.id
        end
      end

      def self.not_plain_text_password password
        password.nil? ? nil : Base64.strict_encode64(password)
      end

      def to_domain
        Domain::Webhook.new(
          uuid: uuid,
          consumer: consumer,
          provider: provider,
          request: Domain::WebhookRequest.new(request_attributes),
          created_at: created_at,
          updated_at: updated_at)
      end

      def request_attributes
        values.merge(headers: parsed_headers, body: parsed_body, password: plain_text_password, uuid: uuid)
      end

      def plain_text_password
        password.nil? ? nil : Base64.strict_decode64(password)
      end

      def parsed_headers
        WebhookHeader.where(webhook_id: id).all.each_with_object({}) do | header, hash |
          hash[header[:name]] = header[:value]
        end
      end

      def parsed_body
        if body && is_json_request_body
           JSON.parse(body)
        else
          body
        end
      end

    end

    Webhook.plugin :timestamps, :update_on_create=>true

    class WebhookHeader < Sequel::Model

      associate(:many_to_one, :webhook, :class => "PactBroker::Repositories::Webhook", :key => :webhook_id, :primary_key => :id)

      def self.from_domain name, value, webhook_id
        db_header = new
        db_header.name = name
        db_header.value = value
        db_header.webhook_id = webhook_id
        db_header
      end

    end
  end

end
