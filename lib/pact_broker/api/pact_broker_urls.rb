require 'erb'

module PactBroker
  module Api
    module PactBrokerUrls

      # TODO make base_url the last and optional argument for all methods, defaulting to ''

      extend self

      def pacticipants_url base_url
        "#{base_url}/pacticipants"
      end

      def pacticipant_url base_url, pacticipant
        "#{pacticipants_url(base_url)}/#{url_encode(pacticipant.name)}"
      end

      def pacticipant_url_from_params params, base_url = ''
        [
          base_url,
          'pacticipants',
          url_encode(params.fetch(:pacticipant_name))
        ].join("/")
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

      def version_url_from_params params, base_url = ''
        [
          base_url,
          'pacticipants',
          url_encode(params.fetch(:pacticipant_name)),
          'versions',
          url_encode(params.fetch(:version_number)),
        ].join("/")
      end

      def pact_url base_url, pact
        "#{pactigration_base_url(base_url, pact)}/version/#{url_encode(pact.consumer_version_number)}"
      end

      def pact_version_url pact, base_url = ''
        "#{pactigration_base_url(base_url, pact)}/pact-version/#{pact.pact_version_sha}"
      end

      def pact_version_url_with_metadata pact, base_url = ''
        "#{pactigration_base_url(base_url, pact)}/pact-version/#{pact.pact_version_sha}/metadata/#{build_webhook_metadata(pact)}"
      end

      def build_webhook_metadata(pact)
        Base64.strict_encode64(Rack::Utils.build_nested_query(
          consumer_version_number: pact.consumer_version_number,
          consumer_version_tags: pact.consumer_version_tag_names
        ))
      end

      def parse_webhook_metadata(metadata)
        if metadata
          Rack::Utils.parse_nested_query(Base64.strict_decode64(metadata)).each_with_object({}) do | (k, v), new_hash |
            new_hash[k.to_sym] = v
          end
        else
          {}
        end
      end

      def pact_url_from_params base_url, params
        [ base_url, 'pacts',
          'provider', url_encode(params[:provider_name]),
          'consumer', url_encode(params[:consumer_name]),
          'version', url_encode(params[:consumer_version_number]) ].join('/')
      end

      def latest_pact_url base_url, pact
        "#{pactigration_base_url(base_url, pact)}/latest"
      end

      def latest_untagged_pact_url pact, base_url
        "#{pactigration_base_url(base_url, pact)}/latest-untagged"
      end

      def latest_tagged_pact_url pact, tag_name, base_url
        "#{latest_pact_url(base_url, pact)}/#{url_encode(tag_name)}"
      end

      def latest_pacts_url base_url
        "#{base_url}/pacts/latest"
      end

      def pact_versions_url consumer_name, provider_name, base_url = ""
        "#{base_url}/pacts/provider/#{url_encode(provider_name)}/consumer/#{url_encode(consumer_name)}/versions"
      end

      def integration_url consumer_name, provider_name, base_url = ""
        "#{base_url}/integrations/provider/#{url_encode(provider_name)}/consumer/#{url_encode(consumer_name)}"
      end

      def dashboard_url_for_integration consumer_name, provider_name, base_url = ""
        "#{base_url}/dashboard/provider/#{url_encode(provider_name)}/consumer/#{url_encode(consumer_name)}"
      end

      def previous_distinct_diff_url pact, base_url
        pact_url(base_url, pact) + "/diff/previous-distinct"
      end

      def templated_diff_url pact, base_url = ''
        pact_version_url(pact, base_url) + "/diff/pact-version/{pactVersion}"
      end

      def previous_distinct_pact_version_url pact, base_url
        pact_url(base_url, pact) + "/previous-distinct"
      end

      def tags_url base_url, version
        "#{version_url(base_url, version)}/tags"
      end

      def new_verification_url pact, number, base_url
        [ base_url, 'pacts',
          'provider', url_encode(pact.provider_name),
          'consumer', url_encode(pact.consumer_name),
          'pact-version', pact.pact_version_sha,
          'verification-results', number
        ].join('/')
      end

      def verification_url verification, base_url = ''
        [ base_url, 'pacts',
          'provider', url_encode(verification.provider_name),
          'consumer', url_encode(verification.consumer_name),
          'pact-version', verification.pact_version_sha,
          'verification-results', verification.number
        ].join('/')
      end

      def verification_url_from_params params, base_url = ''
        [ base_url, 'pacts',
          'provider', url_encode(params.fetch(:provider_name)),
          'consumer', url_encode(params.fetch(:consumer_name)),
          'pact-version', params.fetch(:pact_version_sha),
          'verification-results', params.fetch(:verification_number)
        ].join('/')
      end

      def latest_verifications_for_consumer_version_url version, base_url
        "#{base_url}/verification-results/consumer/#{url_encode(version.pacticipant.name)}/version/#{version.number}/latest"
      end

      def latest_verification_for_pact_url pact, base_url, permalink = true
        if permalink
          verification_url_from_params(
            {
              provider_name: provider_name(pact),
              consumer_name: consumer_name(pact),
              pact_version_sha: pact.pact_version_sha,
              verification_number: 'latest'
            },
            base_url
          )
        else
          pact_url(base_url, pact) + "/verification-results/latest"
        end
      end

      def verification_triggered_webhooks_url verification, base_url = ''
        "#{verification_url(verification, base_url)}/triggered-webhooks"
      end

      def verification_publication_url pact, base_url, metadata = ""
        metadata_part = metadata ? "/metadata/#{metadata}" : ""
        "#{pactigration_base_url(base_url, pact)}/pact-version/#{pact.pact_version_sha}#{metadata_part}/verification-results"
      end

      def tag_url base_url, tag
        "#{tags_url(base_url, tag.version)}/#{tag.name}"
      end

      def templated_tag_url_for_pacticipant pacticipant_name, base_url = ""
        pacticipant_url_from_params({pacticipant_name: pacticipant_name}, base_url) + "/versions/{version}/tags/{tag}"
      end

      def templated_label_url_for_pacticipant pacticipant_name, base_url = ""
        pacticipant_url_from_params({pacticipant_name: pacticipant_name}, base_url) + "/labels/{label}"
      end

      def label_url label, base_url
        "#{labels_url(label.pacticipant, base_url)}/#{label.name}"
      end

      def labels_url pacticipant, base_url
        "#{pacticipant_url(base_url, pacticipant)}/labels"
      end

      def webhooks_url base_url
        "#{base_url}/webhooks"
      end

      def webhook_url uuid, base_url
        "#{base_url}/webhooks/#{uuid}"
      end

      def webhook_execution_url webhook, base_url
        "#{base_url}/webhooks/#{webhook.uuid}/execute"
      end

      def webhooks_for_consumer_and_provider_url consumer, provider, base_url = ''
        "#{base_url}/webhooks/provider/#{url_encode(provider.name)}/consumer/#{url_encode(consumer.name)}"
      end

      def consumer_webhooks_url consumer, base_url = ''
        "#{base_url}/webhooks/consumer/#{url_encode(consumer.name)}"
      end

      def provider_webhooks_url provider, base_url = ''
        "#{base_url}/webhooks/provider/#{url_encode(provider.name)}"
      end

      def webhooks_for_pact_url consumer, provider, base_url = ''
        "#{base_url}/pacts/provider/#{url_encode(provider.name)}/consumer/#{url_encode(consumer.name)}/webhooks"
      end

      def webhooks_status_url consumer, provider, base_url = ''
        "#{webhooks_for_pact_url(consumer, provider, base_url)}/status"
      end

      def pact_triggered_webhooks_url pact, base_url = ''
        "#{pact_url(base_url, pact)}/triggered-webhooks"
      end

      def triggered_webhook_logs_url triggered_webhook, base_url
        "#{base_url}/webhooks/#{triggered_webhook.webhook_uuid}/trigger/#{triggered_webhook.trigger_uuid}/logs"
      end

      def badge_url_for_latest_pact pact, base_url = ''
        "#{latest_pact_url(base_url, pact)}/badge.svg"
      end

      def matrix_url consumer_name, provider_name, base_url = ''
        "/matrix/provider/#{url_encode(provider_name)}/consumer/#{url_encode(consumer_name)}"
      end

      def matrix_url_from_params params, base_url = ''
        matrix_url(params.fetch(:consumer_name), params.fetch(:provider_name), base_url)
      end

      def group_url(pacticipant_name, base_url = '')
        "#{base_url}/groups/#{pacticipant_name}"
      end

      def hal_browser_url target_url
        "/hal-browser/browser.html#" + target_url
      end

      def url_encode param
        ERB::Util.url_encode param
      end

      private

      def representable_pact pact
        Decorators::RepresentablePact === pact ? pact : Decorators::RepresentablePact.new(pact)
      end

      def pactigration_base_url base_url, pact
        provider_name = pact.respond_to?(:provider_name) ? pact.provider_name : pact.provider.name
        consumer_name = pact.respond_to?(:consumer_name) ? pact.consumer_name : pact.consumer.name
        "#{base_url}/pacts/provider/#{url_encode(provider_name)}/consumer/#{url_encode(consumer_name)}"
      end

      def pactigration_base_url_from_params base_url, params
        [ base_url, 'pacts',
          'provider', url_encode(params[:provider_name]),
          'consumer', url_encode(params[:consumer_name])
        ].join('/')
      end

      def consumer_name(thing)
        if thing.respond_to?(:consumer_name)
          thing.consumer_name
        elsif thing.respond_to?(:consumer)
          thing.consumer.name
        elsif thing.respond_to?(:[])
          thing[:consumer_name]
        else
          nil
        end
      end

      def provider_name(thing)
        if thing.respond_to?(:provider_name)
          thing.provider_name
        elsif thing.respond_to?(:provider)
          thing.provider.name
        elsif thing.respond_to?(:[])
          thing[:provider_name]
        else
          nil
        end
      end
    end
  end
end
