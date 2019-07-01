module PactBroker
  module Webhooks
    class PactAndVerificationParameters

      def initialize(pact, trigger_verification, webhook_context)
        @pact = pact
        @verification = trigger_verification || (pact && pact.latest_verification)
        @webhook_context = webhook_context
        @base_url = webhook_context.fetch(:base_url)
      end

      def to_hash
        @hash ||= {
          '${pactbroker.pactUrl}' => pact ? PactBroker::Api::PactBrokerUrls.pact_version_url_with_metadata(pact, base_url) : "",
          '${pactbroker.verificationResultUrl}' => verification_url,
          '${pactbroker.consumerVersionNumber}' => consumer_version_number,
          '${pactbroker.providerVersionNumber}' => verification ? verification.provider_version_number : "",
          '${pactbroker.providerVersionTags}' => provider_version_tags,
          '${pactbroker.consumerVersionTags}' => consumer_version_tags,
          '${pactbroker.consumerName}' => pact ? pact.consumer_name : "",
          '${pactbroker.providerName}' => pact ? pact.provider_name : "",
          '${pactbroker.githubVerificationStatus}' => github_verification_status,
          '${pactbroker.bitbucketVerificationStatus}' => bitbucket_verification_status,
          '${pactbroker.consumerLabels}' => pacticipant_labels(pact && pact.consumer),
          '${pactbroker.providerLabels}' => pacticipant_labels(pact && pact.provider)
        }
      end

      private

      attr_reader :pact, :verification, :webhook_context, :base_url

      def bitbucket_verification_status
        if verification
          verification.success ? "SUCCESSFUL" : "FAILED"
        else
          "INPROGRESS"
        end
      end

      def github_verification_status
        if verification
          verification.success ? "success" : "failure"
        else
          "pending"
        end
      end

      def verification_url
        if verification
          PactBroker::Api::PactBrokerUrls.verification_url(verification, base_url)
        else
          ""
        end
      end

      def consumer_version_number
        if webhook_context[:consumer_version_number]
          webhook_context[:consumer_version_number]
        else
          pact ? pact.consumer_version_number : ""
        end
      end

      def consumer_version_tags
        if webhook_context[:consumer_version_tags]
          webhook_context[:consumer_version_tags].join(", ")
        else
          if pact
            pact.consumer_version.tags.collect(&:name).join(", ")
          else
            ""
          end
        end
      end

      def provider_version_tags
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

      def pacticipant_labels pacticipant
        pacticipant && pacticipant.labels ? pacticipant.labels.collect(&:name).join(", ") : ""
      end
    end
  end
end