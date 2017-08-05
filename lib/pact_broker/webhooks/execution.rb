require 'sequel'

module PactBroker
  module Webhooks
    class Execution < Sequel::Model(:webhook_executions)

      associate(:many_to_one, :webhook, :class => "PactBroker::Webhooks::Webhook", :key => :webhook_id, :primary_key => :id)
      associate(:many_to_one, :pact_publication, :class => "PactBroker::Pacts::PactPublication", :key => :pact_publication_id, :primary_key => :id)
      associate(:many_to_one, :provider, :class => "PactBroker::Domain::Pacticipant", :key => :provider_id, :primary_key => :id)
      associate(:many_to_one, :consumer, :class => "PactBroker::Domain::Pacticipant", :key => :consumer_id, :primary_key => :id)


      def <=> other
        comp = created_date <=> other.created_date
        comp = id <=> other.id if comp == 0
        comp
      end
    end

    Execution.plugin :timestamps

  end
end
