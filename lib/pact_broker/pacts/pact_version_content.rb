require 'sequel'

module PactBroker
  module Pacts
    class PactVersionContent < Sequel::Model(:pact_version_contents)

      one_to_many :pact_revisions, :reciprocal => :pact_version_content

      def name
        "Pact between #{consumer_name} and #{provider_name}"
      end

      def provider_name
        pact_revisions.last.provider.name
      end

      def consumer_name
        pact_revisions.last.consumer.name
      end

      def latest_consumer_version
        consumer_versions.last
      end

      def latest_pact_revision
        latest_consumer_version.latest_pact_revision
      end

      def consumer_versions
        PactBroker::Domain::Version.where(id: PactBroker::Pacts::PactRevision.select(:consumer_version_id).where(pact_version_content_id: id)).order(:order)
      end

      def latest_consumer_version_number
        latest_consumer_version.number
      end
    end

    PactVersionContent.plugin :timestamps
  end
end
