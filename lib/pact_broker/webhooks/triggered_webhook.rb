require 'sequel'
require 'pact_broker/repositories/helpers'
require 'pact_broker/webhooks/execution'

module PactBroker
  module Webhooks
    class TriggeredWebhook < Sequel::Model(:triggered_webhooks)

      TRIGGER_TYPE_PUBLICATION = 'pact_publication'
      TRIGGER_TYPE_USER = 'user'

      STATUS_NOT_RUN = 'not_run'
      STATUS_RETRYING = 'retrying'
      STATUS_SUCCESS = 'success'
      STATUS_FAILURE = 'failure'

      dataset_module do
        include PactBroker::Repositories::Helpers
      end

      associate(:one_to_many, :webhook_executions, :class => "PactBroker::Webhooks::Execution", :key => :triggered_webhook_id, :primary_key => :id, :order => :id)
      associate(:many_to_one, :webhook, :class => "PactBroker::Webhooks::Webhook", :key => :webhook_id, :primary_key => :id)
      associate(:many_to_one, :pact_publication, :class => "PactBroker::Pacts::PactPublication", :key => :pact_publication_id, :primary_key => :id)
      associate(:many_to_one, :provider, :class => "PactBroker::Domain::Pacticipant", :key => :provider_id, :primary_key => :id)
      associate(:many_to_one, :consumer, :class => "PactBroker::Domain::Pacticipant", :key => :consumer_id, :primary_key => :id)

      def request_description
        webhook.to_domain.request_description
      end

      def execute
        webhook.to_domain.execute
      end

      def consumer_name
        consumer && consumer.name
      end

      def provider_name
        provider && provider.name
      end
    end

    TriggeredWebhook.plugin :timestamps, update_on_create: true

  end
end
