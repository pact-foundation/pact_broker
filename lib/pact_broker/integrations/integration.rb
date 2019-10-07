require 'pact_broker/db'
require 'pact_broker/verifications/pseudo_branch_status'
require 'pact_broker/domain/verification'

module PactBroker
  module Integrations
    class Integration < Sequel::Model
      associate(:many_to_one, :consumer, :class => "PactBroker::Domain::Pacticipant", :key => :consumer_id, :primary_key => :id)
      associate(:many_to_one, :provider, :class => "PactBroker::Domain::Pacticipant", :key => :provider_id, :primary_key => :id)
      associate(:one_to_one, :latest_pact, :class => "PactBroker::Pacts::LatestPactPublications", key: [:consumer_id, :provider_id], primary_key: [:consumer_id, :provider_id])

      def verification_status_for_latest_pact
        @verification_status_for_latest_pact ||= PactBroker::Verifications::PseudoBranchStatus.new(latest_pact, latest_pact&.latest_verification)
      end

      def latest_pact_or_verification_publication_date
        [latest_pact.created_at, latest_verification_publication_date].compact.max
      end

      def latest_verification_publication_date
        PactBroker::Domain::Verification.where(consumer_id: consumer_id, provider_id: provider_id).order(:id).last&.execution_date
      end
    end
  end
end

# Table: integrations
# Columns:
#  consumer_id   | integer |
#  consumer_name | text    |
#  provider_id   | integer |
#  provider_name | text    |
