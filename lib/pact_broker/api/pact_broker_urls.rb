module PactBroker
  module Api
    module PactBrokerUrls

      def pacticipants_url base_url
        "#{base_url}/pacticipants"
      end

      def pacticipant_url base_url, pacticipant
        "#{pacticipants_url(base_url)}/#{url_encode(pacticipant.name)}"
      end

      def latest_version_url base_url, pacticipant
        "#{pacticipant_url(base_url, pacticipant)}/versions/latest"
      end

      def versions_url base_url, pacticipant
        "#{pacticipant_url(base_url, pacticipant)}/versions"
      end

      def version_url base_url, version
        "#{pacticipant_url(base_url, version.pacticipant)}/versions/#{version.number}"
      end

      def pact_url base_url, pact
        representable_pact = representable_pact(pact)
        "#{pactigration_base_url(base_url, representable_pact)}/version/#{representable_pact.consumer.version.number}"
      end

      def latest_pact_url base_url, pact
        "#{pactigration_base_url(base_url, pact)}/latest"
      end

      def latest_pacts_url base_url
        "#{base_url}/pacts/latest"
      end

      def tags_url base_url, version
        "#{version_url(base_url, version)}/tags"
      end

      def tag_url base_url, tag
        "#{tags_url(base_url, tag.version)}/#{tag.name}"
      end

      def webhook_url webhook, base_url
        "#{base_url}/#{webhook.uuid}"
      end

      private

      def representable_pact pact
        Decorators::RepresentablePact === pact ? pact : Decorators::RepresentablePact.new(pact)
      end

      def pactigration_base_url base_url, pact
        "#{base_url}/pacts/provider/#{url_encode(pact.provider.name)}/consumer/#{url_encode(pact.consumer.name)}"
      end

      def url_encode param
        ERB::Util.url_encode param
      end
    end
  end
end