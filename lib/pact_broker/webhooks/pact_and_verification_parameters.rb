module PactBroker
  module Webhooks
    class PactAndVerificationParameters
      PACT_URL = 'pactbroker.pactUrl'
      VERIFICATION_RESULT_URL = 'pactbroker.verificationResultUrl'
      CONSUMER_VERSION_NUMBER = 'pactbroker.consumerVersionNumber'
      PROVIDER_VERSION_NUMBER = 'pactbroker.providerVersionNumber'
      PROVIDER_VERSION_TAGS = 'pactbroker.providerVersionTags'
      CONSUMER_VERSION_TAGS = 'pactbroker.consumerVersionTags'
      CONSUMER_NAME = 'pactbroker.consumerName'
      PROVIDER_NAME = 'pactbroker.providerName'
      GITHUB_VERIFICATION_STATUS = 'pactbroker.githubVerificationStatus'
      BITBUCKET_VERIFICATION_STATUS = 'pactbroker.bitbucketVerificationStatus'
      CONSUMER_LABELS = 'pactbroker.consumerLabels'
      PROVIDER_LABELS = 'pactbroker.providerLabels'
      EVENT_NAME = 'pactbroker.eventName'

      ALL = [
        CONSUMER_NAME,
        PROVIDER_NAME,
        CONSUMER_VERSION_NUMBER,
        PROVIDER_VERSION_NUMBER,
        PROVIDER_VERSION_TAGS,
        CONSUMER_VERSION_TAGS,
        PACT_URL,
        VERIFICATION_RESULT_URL,
        GITHUB_VERIFICATION_STATUS,
        BITBUCKET_VERIFICATION_STATUS,
        CONSUMER_LABELS,
        PROVIDER_LABELS,
        EVENT_NAME
      ]

      def initialize(pact, trigger_verification, webhook_context)
        @pact = pact
        @verification = trigger_verification || (pact && pact.latest_verification)
        @webhook_context = webhook_context
        @base_url = webhook_context.fetch(:base_url)
      end

      def to_hash
        @hash ||= {
          PACT_URL => pact ? PactBroker::Api::PactBrokerUrls.pact_version_url_with_webhook_metadata(pact, base_url) : "",
          VERIFICATION_RESULT_URL => verification_url,
          CONSUMER_VERSION_NUMBER => consumer_version_number,
          PROVIDER_VERSION_NUMBER => verification ? verification.provider_version_number : "",
          PROVIDER_VERSION_TAGS => provider_version_tags,
          CONSUMER_VERSION_TAGS => consumer_version_tags,
          CONSUMER_NAME => pact ? pact.consumer_name : "",
          PROVIDER_NAME => pact ? pact.provider_name : "",
          GITHUB_VERIFICATION_STATUS => github_verification_status,
          BITBUCKET_VERIFICATION_STATUS => bitbucket_verification_status,
          CONSUMER_LABELS => pacticipant_labels(pact && pact.consumer),
          PROVIDER_LABELS => pacticipant_labels(pact && pact.provider),
          EVENT_NAME => event_name
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

      def event_name
        webhook_context.fetch(:event_name)
      end
    end
  end
end
