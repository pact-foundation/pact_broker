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
        uuid = SecureRandom.urlsafe_base64
        is_json_request_body = !(String === webhook.request.body || webhook.request.body.nil?) # Can't rely on people to set content type
        webhook_id = PactBroker::DB.connection[:webhooks].
          insert(
            consumer_id: consumer.id,
            provider_id: provider.id,
            uuid: uuid,
            method: webhook.request.method,
            url: webhook.request.url,
            body: (is_json_request_body ? webhook.request.body.to_json : webhook.request.body),
            is_json_request_body: is_json_request_body
          )

        webhook.request.headers.each_pair do | name, value |
          PactBroker::DB.connection[:webhook_headers].insert(name: name, value: value, webhook_id: webhook_id)
        end

        find_by_uuid uuid
      end

      def find_by_uuid uuid
        webhook_record = PactBroker::DB.connection[:webhooks].where(uuid: uuid).single_record
        return nil if webhook_record.nil?
        create_webhook_model webhook_record
      end

      private

      def create_webhook_model webhook_record
        headers = find_webhook_headers webhook_record[:id]
        body = webhook_body_from webhook_record
        request_record = webhook_record.merge(headers: headers, body: body)
        Models::Webhook.new(
          uuid: webhook_record[:uuid],
          consumer: pacticipant_repository.find_by_id(webhook_record[:consumer_id]),
          provider: pacticipant_repository.find_by_id(webhook_record[:provider_id]),
          request: Models::WebhookRequest.new(request_record))
      end

      def find_webhook_headers webhook_id
        header_records = PactBroker::DB.connection[:webhook_headers].where(webhook_id: webhook_id)
        header_records.each_with_object({}) { | header, hash | hash[header[:name]] = header[:value]}
      end

      def webhook_body_from webhook_record
        if webhook_record[:body] && webhook_record[:is_json_request_body]
           JSON.parse(webhook_record[:body])
        else
          webhook_record[:body]
        end
      end

    end
  end
end