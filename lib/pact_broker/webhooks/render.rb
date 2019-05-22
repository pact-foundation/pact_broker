module PactBroker
  module Webhooks
    class Render

      TEMPLATE_PARAMETER_REGEXP = /\$\{pactbroker\.[^\}]+\}/

      def self.call(template, pact, trigger_verification, webhook_context, &escaper)
        base_url = webhook_context[:base_url]
        verification = trigger_verification || (pact && pact.latest_verification)
        params = {
          '${pactbroker.pactUrl}' => pact ? PactBroker::Api::PactBrokerUrls.pact_version_url_with_metadata(pact, base_url) : "",
          '${pactbroker.verificationResultUrl}' => verification_url(verification, base_url),
          '${pactbroker.consumerVersionNumber}' => consumer_version_number(pact, webhook_context),
          '${pactbroker.providerVersionNumber}' => verification ? verification.provider_version_number : "",
          '${pactbroker.providerVersionTags}' => provider_version_tags(verification, webhook_context),
          '${pactbroker.consumerVersionTags}' => consumer_version_tags(pact, webhook_context),
          '${pactbroker.consumerName}' => pact ? pact.consumer_name : "",
          '${pactbroker.providerName}' => pact ? pact.provider_name : "",
          '${pactbroker.githubVerificationStatus}' => github_verification_status(verification),
          '${pactbroker.consumerLabels}' => pacticipant_labels(pact && pact.consumer),
          '${pactbroker.providerLabels}' => pacticipant_labels(pact && pact.provider)
        }

        if escaper
          params.keys.each do | key |
            params[key] = escaper.call(params[key])
          end
        end

        params.inject(template) do | template, (key, value) |
          template.gsub(key, value)
        end
      end

      def self.github_verification_status verification
        if verification
          verification.success ? "success" : "failure"
        else
          "pending"
        end
      end

      def self.verification_url verification, base_url
        if verification
          PactBroker::Api::PactBrokerUrls.verification_url(verification, base_url)
        else
          ""
        end
      end

      def self.consumer_version_number(pact, webhook_context)
        if webhook_context[:upstream_webhook_pact_metadata] && webhook_context[:upstream_webhook_pact_metadata][:consumer_version_number]
          webhook_context[:upstream_webhook_pact_metadata][:consumer_version_number]
        else
          pact ? pact.consumer_version_number : ""
        end
      end

      def self.consumer_version_tags pact, webhook_context
        if webhook_context[:upstream_webhook_pact_metadata] && webhook_context[:upstream_webhook_pact_metadata][:consumer_version_tags]
          webhook_context[:upstream_webhook_pact_metadata][:consumer_version_tags].join(", ")
        else
          if pact
            pact.consumer_version.tags.collect(&:name).join(", ")
          else
            ""
          end
        end
      end

      def self.provider_version_tags verification, webhook_context
        if webhook_context[:provider_version_tags]
          webhook_context[:provider_version_tags].join(", ")
        else
          if verification
            verification.provider_version.tags.collect(&:name).join(", ")
          else
            ""
          end
        end
      end

      def self.pacticipant_labels pacticipant
        pacticipant && pacticipant.labels ? pacticipant.labels.collect(&:name).join(", ") : ""
      end
    end
  end
end
