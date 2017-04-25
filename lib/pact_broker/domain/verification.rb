require 'pact_broker/db'

module PactBroker

  module Domain
    class Verification < Sequel::Model

      set_primary_key :id
      associate(:many_to_one, :pact_version, class: "PactBroker::Pacts::PactVersion", key: :pact_version_id, primary_key: :id)

      def before_create
        super
        self.execution_date ||= DateTime.now
      end

      def consumer_name
        consumer.name
      end

      def provider_name
        provider.name
      end

      def consumer
        Pacticipant.find(id: PactBroker::Pacts::AllPactPublications
           .where(pact_version_id: pact_version_id)
           .limit(1).select(:consumer_id))
      end

      def provider
        Pacticipant.find(id: PactBroker::Pacts::AllPactPublications
           .where(pact_version_id: pact_version_id)
           .limit(1).select(:provider_id))
      end

      def latest_pact_publication
        pact_version.latest_pact_publication
      end

    end

    Verification.plugin :timestamps, update_on_create: true
  end
end
