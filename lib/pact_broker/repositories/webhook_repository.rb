require 'sequel'
require 'pact_broker/models/webhook'
require 'pact_broker/db'

module PactBroker
  module Repositories

    class WebhookRepository

      # Experimenting with decoupling the model from the database representation.
      # Sure makes it messier for saving/retrieving.

      include Repositories

      def create webhook, consumer, provider
        db_webhook = Webhook.from_model webhook, consumer, provider
        db_webhook.uuid = SecureRandom.urlsafe_base64
        db_webhook.save
        webhook.request.headers.each_pair do | name, value |
          db_webhook.add_header WebhookHeader.from_model(name, value, db_webhook.id)
        end

        find_by_uuid db_webhook.uuid
      end

      def find_by_uuid uuid
        db_webhook = Webhook.where(uuid: uuid).single_record
        return nil if db_webhook.nil?
        db_webhook.to_model
      end

      def delete_by_uuid uuid
        Webhook.where(uuid: uuid).destroy
      end

      def delete_by_pacticipant pacticipant
        Webhook.where(consumer_id: pacticipant.id).destroy
        Webhook.where(provider_id: pacticipant.id).destroy
      end

      def find_all
        Webhook.all.collect { | db_webhook| db_webhook.to_model }
      end

      def find_by_consumer_and_provider consumer, provider
        Webhook.where(consumer_id: consumer.id, provider_id: provider.id).collect { | db_webhook| db_webhook.to_model }
      end

    end

    class Webhook < Sequel::Model

      set_primary_key :id
      associate(:many_to_one, :provider, :class => "PactBroker::Models::Pacticipant", :key => :provider_id, :primary_key => :id)
      associate(:many_to_one, :consumer, :class => "PactBroker::Models::Pacticipant", :key => :consumer_id, :primary_key => :id)
      one_to_many :headers, :class => "PactBroker::Repositories::WebhookHeader", :reciprocal => :webhook

      def before_destroy
        WebhookHeader.where(webhook_id: id).destroy
      end

      def self.from_model webhook, consumer, provider
        is_json_request_body = !(String === webhook.request.body || webhook.request.body.nil?) # Can't rely on people to set content type
        new(
          uuid: webhook.uuid,
          method: webhook.request.method,
          url: webhook.request.url,
          username: webhook.request.username,
          password: webhook.request.password,
          body: (is_json_request_body ? webhook.request.body.to_json : webhook.request.body),
          is_json_request_body: is_json_request_body
        ).tap do | db_webhook |
          db_webhook.consumer_id = consumer.id
          db_webhook.provider_id = provider.id
        end
      end

      def to_model
        Models::Webhook.new(
          uuid: uuid,
          consumer: consumer,
          provider: provider,
          request: Models::WebhookRequest.new(request_attributes))
      end

      def request_attributes
        values.merge(headers: parsed_headers, body: parsed_body)
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

      def self.from_model name, value, webhook_id
        db_header = new
        db_header.name = name
        db_header.value = value
        db_header.webhook_id = webhook_id
        db_header
      end

    end
  end
end