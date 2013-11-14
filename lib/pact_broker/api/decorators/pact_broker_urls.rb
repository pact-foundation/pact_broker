module PactBroker
  module Api
    module PactBrokerUrls

      BASE_URL_PLACEHOLDER = "http://_______PACT_BROKER_BASE_URL_PLACEHOLDER_TO_BE_REPLACED_AFTER_TO_JSON_______"

      def base_url_placeholder
        BASE_URL_PLACEHOLDER
      end

      def pacticipants_url
        "#{base_url_placeholder}/pacticipants"
      end

      def pacticipant_url pacticipant
        "#{pacticipants_url}/#{url_encode(pacticipant.name)}"
      end

      def last_version_url pacticipant
        "#{pacticipant_url(pacticipant)}/versions/last"
      end

      def versions_url pacticipant
        "#{pacticipant_url(pacticipant)}/versions"
      end

      def version_url version
        "#{pacticipant_url(version.pacticipant)}/versions/#{version.number}"
      end

      def pact_url pact
        "#{pactigration_base_url(pact)}/version/#{pact.consumer.version.number}"
      end

      def latest_pact_url pact
        "#{pactigration_base_url(pact)}/latest"
      end

      def latest_pacts_url
        "#{base_url_placeholder}/pacts/latest"
      end

      private

      def pactigration_base_url pact
        "#{base_url_placeholder}/pact/provider/#{url_encode(pact.provider.name)}/consumer/#{url_encode(pact.consumer.name)}"
      end

      def url_encode param
        ERB::Util.url_encode param
      end
    end
  end
end