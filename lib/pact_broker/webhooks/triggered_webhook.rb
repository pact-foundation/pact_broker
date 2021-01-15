require 'sequel'
require 'pact_broker/repositories/helpers'
require 'pact_broker/webhooks/execution'

# Represents the relationship between a webhook and the event and object
# that caused it to be triggered. eg a pact publication

module PactBroker
  module Webhooks
    class TriggeredWebhook < Sequel::Model(:triggered_webhooks)
      plugin :timestamps, update_on_create: true
      plugin :serialization, :json, :context

      TRIGGER_TYPE_RESOURCE_CREATION = 'resource_creation'
      TRIGGER_TYPE_USER = 'user'

      STATUS_NOT_RUN = 'not_run'.freeze
      STATUS_RETRYING = 'retrying'.freeze
      STATUS_SUCCESS = 'success'.freeze
      STATUS_FAILURE = 'failure'.freeze

      dataset_module do
        include PactBroker::Repositories::Helpers

        def delete
          require 'pact_broker/webhooks/execution'
          PactBroker::Webhooks::Execution.where(triggered_webhook: self).delete
          super
        end

        def retrying
          where(status: STATUS_RETRYING)
        end

        def successful
          where(status: STATUS_SUCCESS)
        end

        def failed
          where(status: STATUS_FAILURE)
        end

        def not_run
          where(status: STATUS_NOT_RUN)
        end
      end

      associate(:one_to_many, :webhook_executions, :class => "PactBroker::Webhooks::Execution", :key => :triggered_webhook_id, :primary_key => :id, :order => :id)
      associate(:many_to_one, :webhook, :class => "PactBroker::Webhooks::Webhook", :key => :webhook_id, :primary_key => :id)
      associate(:many_to_one, :pact_publication, :class => "PactBroker::Pacts::PactPublication", :key => :pact_publication_id, :primary_key => :id)
      associate(:many_to_one, :verification, :class => "PactBroker::Domain::Verification", :key => :verification_id, :primary_key => :id)
      associate(:many_to_one, :provider, :class => "PactBroker::Domain::Pacticipant", :key => :provider_id, :primary_key => :id)
      associate(:many_to_one, :consumer, :class => "PactBroker::Domain::Pacticipant", :key => :consumer_id, :primary_key => :id)

      def request_description
        webhook.to_domain.request_description
      end

      def execute options
        # getting a random 'no method to_domain for null' error
        # not sure on which object, so splitting this out into two lines
        pact = pact_publication.to_domain
        webhook.to_domain.execute(pact, verification, options)
      end

      def consumer_name
        consumer && consumer.name
      end

      def provider_name
        provider && provider.name
      end

      def success?
        status == STATUS_SUCCESS
      end

      def failure?
        status == STATUS_FAILURE
      end

      def retrying?
        status == STATUS_RETRYING
      end

      def not_run?
        status == STATUS_NOT_RUN
      end

      def number_of_attempts_made
        webhook_executions.size
      end

      def finished?
        success? || failure?
      end

      def number_of_attempts_remaining
        if finished?
          0
        else
          (PactBroker.configuration.webhook_retry_schedule.size + 1) - number_of_attempts_made
        end
      end
    end
  end
end

# Table: triggered_webhooks
# Columns:
#  id                  | integer                     | PRIMARY KEY DEFAULT nextval('triggered_webhooks_id_seq'::regclass)
#  trigger_uuid        | text                        | NOT NULL
#  trigger_type        | text                        | NOT NULL
#  pact_publication_id | integer                     | NOT NULL
#  webhook_id          | integer                     |
#  webhook_uuid        | text                        | NOT NULL
#  consumer_id         | integer                     | NOT NULL
#  provider_id         | integer                     | NOT NULL
#  status              | text                        | NOT NULL
#  created_at          | timestamp without time zone | NOT NULL
#  updated_at          | timestamp without time zone | NOT NULL
#  verification_id     | integer                     |
# Indexes:
#  triggered_webhooks_pkey     | PRIMARY KEY btree (id)
#  uq_triggered_webhook_ppi_wi | UNIQUE btree (pact_publication_id, webhook_id, trigger_uuid)
#  uq_triggered_webhook_wi     | UNIQUE btree (webhook_id, trigger_uuid)
# Foreign key constraints:
#  triggered_webhooks_consumer_id_fkey         | (consumer_id) REFERENCES pacticipants(id)
#  triggered_webhooks_pact_publication_id_fkey | (pact_publication_id) REFERENCES pact_publications(id)
#  triggered_webhooks_provider_id_fkey         | (provider_id) REFERENCES pacticipants(id)
#  triggered_webhooks_verification_id_fkey     | (verification_id) REFERENCES verifications(id)
#  triggered_webhooks_webhook_id_fkey          | (webhook_id) REFERENCES webhooks(id)
# Referenced By:
#  webhook_executions | webhook_executions_triggered_webhook_id_fkey | (triggered_webhook_id) REFERENCES triggered_webhooks(id)
