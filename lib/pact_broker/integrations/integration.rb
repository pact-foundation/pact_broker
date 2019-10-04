require 'pact_broker/db'
require 'pact_broker/verifications/verification_status'

module PactBroker
  module Integrations
    class Integration < Sequel::Model
      associate(:many_to_one, :consumer, :class => "PactBroker::Domain::Pacticipant", :key => :consumer_id, :primary_key => :id)
      associate(:many_to_one, :provider, :class => "PactBroker::Domain::Pacticipant", :key => :provider_id, :primary_key => :id)
      associate(:one_to_one, :latest_pact, :class => "PactBroker::Pacts::LatestPactPublications", key: [:consumer_id, :provider_id], primary_key: [:consumer_id, :provider_id])

      def verification_status_for_latest_pact
        @verification_status_for_latest_pact ||= PactBroker::Verifications::Status.new(latest_pact, latest_pact&.latest_verification)
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
