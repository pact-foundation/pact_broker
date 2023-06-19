require "pact_broker/dataset"
require "pact_broker/verifications/pseudo_branch_status"
require "pact_broker/domain/verification"
require "pact_broker/webhooks/latest_triggered_webhook"
require "pact_broker/webhooks/webhook"
require "pact_broker/verifications/latest_verification_for_consumer_and_provider"

module PactBroker
  module Integrations
    class Integration < Sequel::Model(Sequel::Model.db[:integrations].select(:id, :consumer_id, :provider_id, :contract_data_updated_at))
      set_primary_key :id
      plugin :insert_ignore, identifying_columns: [:consumer_id, :provider_id]
      associate(:many_to_one, :consumer, :class => "PactBroker::Domain::Pacticipant", :key => :consumer_id, :primary_key => :id)
      associate(:many_to_one, :provider, :class => "PactBroker::Domain::Pacticipant", :key => :provider_id, :primary_key => :id)
      associate(:one_to_one, :latest_verification, :class => "PactBroker::Verifications::LatestVerificationForConsumerAndProvider", key: [:consumer_id, :provider_id], primary_key: [:consumer_id, :provider_id])

      one_to_many(:latest_triggered_webhooks,
        :class => PactBroker::Webhooks::TriggeredWebhook,
        key: [:consumer_id, :provider_id],
        allow_eager: true,
        primary_key: [:consumer_id, :provider_id]) do | ds |
          ds.latest_triggered_webhooks
        end

      # When viewing the index, every latest_pact in the database will match at least one of the rows, so
      # it makes sense to load the entire table and match each pact to the appropriate row.
      # Update: now we have pagination, we should probably filter the pacts by consumer/provider id.
      LATEST_PACT_EAGER_LOADER = proc do |eo_opts|
        eo_opts[:rows].each do |integration|
          integration.associations[:latest_pact] = nil
        end


        # Would prefer to be able to eager load only the fields specified in the original Integrations
        # query, but we don't seem to have that information in this context.
        # Need the latest verification for the verification status in the index response.
        latest_pact_publications_query = PactBroker::Pacts::PactPublication
                                          .eager_for_domain_with_content
                                          .eager(pact_version: :latest_verification)
                                          .overall_latest

        latest_pact_publications_query.all.each do | pact |
          eo_opts[:id_map][[pact.consumer_id, pact.provider_id]]&.each do | integration |
            integration.associations[:latest_pact] = pact
          end
        end
      end

      one_to_one(:latest_pact, class: "PactBroker::Pacts::PactPublication", :key => [:consumer_id, :provider_id], primary_key: [:consumer_id, :provider_id], :eager_loader=> LATEST_PACT_EAGER_LOADER) do | _ds |
        # Would prefer to be able to eager load only the fields specified in the original Integrations
        # query, but we don't seem to have that information in this context.
        # Need the latest verification for the verification status in the index response.
        PactBroker::Pacts::PactPublication
          .eager_for_domain_with_content
          .eager(pact_version: :latest_verification)
          .overall_latest_for_consumer_id_and_provider_id(consumer_id, provider_id)
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
        include PactBroker::Dataset

        def filter_by_pacticipant(query_string)
          matching_pacticipants = PactBroker::Domain::Pacticipant.filter(:name, query_string)
          pacticipants_join = Sequel.|({ Sequel[:integrations][:consumer_id] => Sequel[:p][:id] }, { Sequel[:integrations][:provider_id] => Sequel[:p][:id] })
          join(matching_pacticipants, pacticipants_join, table_alias: :p)
        end

        def including_pacticipant_id(pacticipant_id)
          where(consumer_id: pacticipant_id).or(provider_id: pacticipant_id)
        end
      end

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

      # TODO make this the verification status for the latest from main branch
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

      def pacticipant_ids
        [consumer_id, provider_id]
      end

      def to_s
        "Integration: consumer #{associations[:consumer]&.name || consumer_id}/provider #{associations[:provider]&.name || provider_id}"
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
