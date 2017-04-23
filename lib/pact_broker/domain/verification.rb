require 'pact_broker/db'

module PactBroker

  module Domain
    class Verification < Sequel::Model

      set_primary_key :id
      associate(:many_to_one, :pact_version_content, class: "PactBroker::Pacts::PactVersionContent", key: :pact_version_content_id, primary_key: :id)

      def consumer_name
        consumer.name
      end

      def provider_name
        provider.name
      end

      def consumer
        Pacticipant.find(id: PactBroker::Pacts::AllPactRevisions
           .where(pact_version_content_id: pact_version_content_id)
           .limit(1).select(:consumer_id))
      end

      def provider
        Pacticipant.find(id: PactBroker::Pacts::AllPactRevisions
           .where(pact_version_content_id: pact_version_content_id)
           .limit(1).select(:provider_id))
      end

      def latest_pact_revision
        pact_version_content.latest_pact_revision
      end

    end

    Verification.plugin :timestamps, update_on_create: true
  end
end