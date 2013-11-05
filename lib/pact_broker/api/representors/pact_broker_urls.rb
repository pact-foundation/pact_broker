module PactBroker
  module Api
    module PactBrokerUrls

      def base_url
        "http://localhost:1234"
      end

      def pacticipants_url
        "#{base_url}/pacticipants"
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

      def url_encode param
        ERB::Util.url_encode param
      end
    end
  end
end