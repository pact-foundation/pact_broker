require "pact_broker/db"
require "pact_broker/verifications/pseudo_branch_status"
require "pact_broker/domain/verification"
require "pact_broker/webhooks/latest_triggered_webhook"
require "pact_broker/webhooks/webhook"

module PactBroker
  module Integrations
    class Integration < Sequel::Model
      set_primary_key [:consumer_id, :provider_id]
      associate(:many_to_one, :consumer, :class => "PactBroker::Domain::Pacticipant", :key => :consumer_id, :primary_key => :id)
      associate(:many_to_one, :provider, :class => "PactBroker::Domain::Pacticipant", :key => :provider_id, :primary_key => :id)
      associate(:one_to_one, :latest_verification, :class => "PactBroker::Verifications::LatestVerificationForConsumerAndProvider", key: [:consumer_id, :provider_id], primary_key: [:consumer_id, :provider_id])
      associate(:one_to_many, :latest_triggered_webhooks, :class => "PactBroker::Webhooks::LatestTriggeredWebhook", key: [:consumer_id, :provider_id], primary_key: [:consumer_id, :provider_id])

      # When viewing the index, every latest_pact in the database will match at least one of the rows, so
      # it makes sense to load the entire table and match each pact to the appropriate row.
      # Update: now we have pagination, we should probably filter the pacts by consumer/provider id.
      LATEST_PACT_EAGER_LOADER = proc do |eo_opts|
        eo_opts[:rows].each do |integration|
          integration.associations[:latest_pact] = []
        end

        PactBroker::Pacts::PactPublication.overall_latest.each do | pact |
          eo_opts[:rows].each do | integration |
            if integration.consumer_id == pact.consumer_id && integration.provider_id == pact.provider_id
              integration.associations[:latest_pact] = pact
            end
          end
        end
      end

      one_to_one(:latest_pact, class: "PactBroker::Pacts::PactPublication", :key => [:consumer_id, :provider_id], primary_key: [:consumer_id, :provider_id], :eager_loader=> LATEST_PACT_EAGER_LOADER) do | _ds |
        PactBroker::Pacts::PactPublication.overall_latest_for_consumer_id_and_provider_id(consumer_id, provider_id)
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

      dataset_module do
        def including_pacticipants_with_ids(pacticipant_ids)
          where(Sequel.|({ consumer_id: pacticipant_ids }, { provider_id: pacticipant_ids }))
        end
      end

      def verification_status_for_latest_pact
        @verification_status_for_latest_pact ||= PactBroker::Verifications::PseudoBranchStatus.new(latest_pact, latest_pact&.latest_verification)
      end

      def latest_pact_or_verification_publication_date
        [latest_pact.created_at, latest_verification_publication_date].compact.max
      end

      def latest_verification_publication_date
        latest_verification&.execution_date
      end

      def <=>(other)
        [consumer.name.downcase, provider.name.downcase] <=> [other.consumer.name.downcase, other.provider.name.downcase]
      end

      def pacticipants
        [consumer, provider]
      end
    end
  end
end

# Table: integrations
# Primary Key: (consumer_id, provider_id)
# Columns:
#  consumer_id   | integer |
#  consumer_name | text    |
#  provider_id   | integer |
#  provider_name | text    |
