require 'sequel'

module PactBroker
  module Pacts
    class PactVersion < Sequel::Model(:pact_versions)
      one_to_many :pact_publications, :reciprocal => :pact_version

      def name
        "Pact between #{consumer_name} and #{provider_name}"
      end

      def provider_name
        pact_publications.last.provider.name
      end

      def consumer_name
        pact_publications.last.consumer.name
      end

      def latest_consumer_version
        consumer_versions.last
      end

      def latest_pact_publication
        latest_consumer_version.latest_pact_publication
      end

      def consumer_versions
        PactBroker::Domain::Version.where(id: PactBroker::Pacts::PactPublication.select(:consumer_version_id).where(pact_version_id: id)).order(:order)
      end

      def latest_consumer_version_number
        latest_consumer_version.number
      end
    end

    PactVersion.plugin :timestamps
  end
end
