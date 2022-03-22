require "pact_broker/db"
require "pact_broker/verifications/pseudo_branch_status"
require "pact_broker/domain/verification"
require "pact_broker/webhooks/latest_triggered_webhook"
require "pact_broker/webhooks/webhook"

module PactBroker
  module Integrations
    class Integration < Sequel::Model(Sequel::Model.db[:integrations].select(:id, :consumer_id, :provider_id))
      plugin :insert_ignore, identifying_columns: [:consumer_id, :provider_id]
      associate(:many_to_one, :consumer, :class => "PactBroker::Domain::Pacticipant", :key => :consumer_id, :primary_key => :id)
      associate(:many_to_one, :provider, :class => "PactBroker::Domain::Pacticipant", :key => :provider_id, :primary_key => :id)
      associate(:one_to_one, :latest_verification, :class => "PactBroker::Verifications::LatestVerificationForConsumerAndProvider", key: [:consumer_id, :provider_id], primary_key: [:consumer_id, :provider_id])
      associate(:one_to_many, :latest_triggered_webhooks, :class => "PactBroker::Webhooks::LatestTriggeredWebhook", key: [:consumer_id, :provider_id], primary_key: [:consumer_id, :provider_id])

      # When viewing the index, every latest_pact in the database will match at least one of the rows, so
      # it makes sense to load the entire table and match each pact to the appropriate row.
      # Update: now we have pagination, we should probably filter the pacts by consumer/provider id.
      LATEST_PACT_EAGER_LOADER = proc do |eo_opts|
        eo_opts[:rows].each do |integration|
          integration.associations[:latest_pact] = nil
        end

        # Would prefer to be able to eager load only the fields specified in the original Integrations
        # query, but we don't seem to have that information in this context.
        # We may not need all these assocations eager loaded.
        PactBroker::Pacts::PactPublication.eager_for_domain_with_content.overall_latest.each do | pact |
          eo_opts[:rows].each do | integration |
            if integration.consumer_id == pact.consumer_id && integration.provider_id == pact.provider_id
              integration.associations[:latest_pact] = pact
            end
          end
        end
      end

      one_to_one(:latest_pact, class: "PactBroker::Pacts::PactPublication", :key => [:consumer_id, :provider_id], primary_key: [:consumer_id, :provider_id], :eager_loader=> LATEST_PACT_EAGER_LOADER) do | _ds |
        # Would prefer to be able to eager load only the fields specified in the original Integrations
        # query, but we don't seem to have that information in this context.
        # We may not need all these assocations eager loaded.
        PactBroker::Pacts::PactPublication.eager_for_domain_with_content.overall_latest_for_consumer_id_and_provider_id(consumer_id, provider_id)
      end

      # When viewing the index, every webhook in the database will match at least one of the rows, so
      # it makes sense to load the entire table and match each webhook to the appropriate row.
      # This will only work when using eager loading. The keys are just blanked out to avoid errors.
      # I don't understand how they work at all.
      # It would be nice to do this declaratively.
      many_to_many :webhooks, class: "PactBroker::Webhooks::Webhook", :left_key => [], left_primary_key: [], :eager_loader=>(proc do |eo_opts|
        eo_opts[:rows].each do |integration|
          integration.associations[:webhooks] = []
        end

        PactBroker::Webhooks::Webhook.each do | webhook |
          eo_opts[:rows].each do | integration |
            if webhook.is_for?(integration)
              integration.associations[:webhooks] << webhook
            end
          end
        end
      end)

      def self.compare_by_last_action_date a, b
        if b.latest_pact_or_verification_publication_date && a.latest_pact_or_verification_publication_date
          b.latest_pact_or_verification_publication_date <=> a.latest_pact_or_verification_publication_date
        elsif b.latest_pact_or_verification_publication_date
          1
        elsif a.latest_pact_or_verification_publication_date
          -1
        else
          a <=> b
        end
      end

      def verification_status_for_latest_pact
        @verification_status_for_latest_pact ||= PactBroker::Verifications::PseudoBranchStatus.new(latest_pact, latest_pact&.latest_verification)
      end

      def latest_pact_or_verification_publication_date
        [latest_pact&.created_at, latest_verification_publication_date].compact.max
      end

      def latest_verification_publication_date
        latest_verification&.execution_date
      end

      def <=>(other)
        [consumer_name.downcase, provider_name.downcase] <=> [other.consumer_name.downcase, other.provider_name.downcase]
      end

      def consumer_name
        consumer.name
      end

      def provider_name
        provider.name
      end
    end
  end
end

# Table: integrations
# Columns:
#  id          | integer | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  consumer_id | integer | NOT NULL
#  provider_id | integer | NOT NULL
# Indexes:
#  integrations_pkey                           | PRIMARY KEY btree (id)
#  integrations_consumer_id_provider_id_unique | UNIQUE btree (consumer_id, provider_id)
# Foreign key constraints:
#  integrations_consumer_id_foreign_key | (consumer_id) REFERENCES pacticipants(id) ON DELETE CASCADE
#  integrations_provider_id_foreign_key | (provider_id) REFERENCES pacticipants(id) ON DELETE CASCADE
