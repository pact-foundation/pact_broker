require 'pact_broker/verifications/verification_status'
require 'pact_broker/webhooks/status'

module PactBroker
  module Domain
    class IndexItem

      attr_reader :consumer, :provider, :latest_pact, :latest_verification, :webhooks, :triggered_webhooks, :latest_verification_latest_tags

      def initialize consumer, provider, latest_pact = nil, latest = true, latest_verification = nil, webhooks = [], triggered_webhooks = [], tags = [], latest_verification_latest_tags = []
        @consumer = consumer
        @provider = provider
        @latest_pact = latest_pact
        @latest = latest
        @latest_verification = latest_verification
        @webhooks = webhooks
        @triggered_webhooks = triggered_webhooks
        @tags = tags
        @latest_verification_latest_tags = latest_verification_latest_tags
      end

      def self.create consumer, provider, latest_pact, latest, latest_verification, webhooks = [], triggered_webhooks = [], tags = [], latest_verification_latest_tags = []
        new consumer, provider, latest_pact, latest, latest_verification, webhooks, triggered_webhooks, tags, latest_verification_latest_tags
      end

      def eq? other
        IndexItem === other && other.consumer == consumer && other.provider == provider &&
          other.latest_pact == latest_pact &&
          other.latest? == latest? &&
          other.latest_verification == latest_verification &&
          other.webhooks == webhooks
      end

      def == other
        eq?(other)
      end

      def consumer_name
        consumer.name
      end

      def provider_name
        provider.name
      end

      def latest_pact
        @latest_pact
      end

      def latest?
        @latest
      end

      def consumer_version_number
        @latest_pact.consumer_version_number
      end

      def consumer_version
        @latest_pact.consumer_version
      end

      def provider_version
        @latest_verification ? @latest_verification.provider_version : nil
      end

      def provider_version_number
        @latest_verification ? @latest_verification.provider_version_number : nil
      end

      # these are the consumer tag names for which this pact publication
      # is the latest with that tag
      def tag_names
        @tags
      end

      def any_webhooks?
        @webhooks.any?
      end

      def webhook_status
        @webhook_status ||= PactBroker::Webhooks::Status.new(@latest_pact, @webhooks, @triggered_webhooks).to_sym
      end

      def last_webhook_execution_date
        @last_webhook_execution_date ||= @triggered_webhooks.any? ? @triggered_webhooks.sort{|a, b| a.created_at <=> b.created_at }.last.created_at : nil
      end

      def verification_status
        @verification_status ||= PactBroker::Verifications::Status.new(@latest_pact, @latest_verification).to_sym
      end

      def ever_verified?
        !!latest_verification
      end

      def latest_verification
        @latest_verification
      end

      def latest_verification_successful?
        latest_verification.success
      end

      def pact_changed_since_last_verification?
        latest_verification.pact_version_sha != latest_pact.pact_version_sha
      end

      def latest_verification_provider_version_number
        latest_verification.provider_version.number
      end

      def pacticipants
        [consumer, provider]
      end

      def connected? other
        include?(other.consumer) || include?(other.provider)
      end

      def include? pacticipant
        pacticipant.id == consumer.id || pacticipant.id == provider.id
      end

      def <=> other
        comp = consumer_name <=> other.consumer_name
        return comp unless comp == 0
        provider_name <=> other.provider_name
      end

      def to_s
        "Pact between #{consumer_name} #{consumer_version_number} and #{provider_name} #{provider_version_number}"
      end

      def to_a
        [consumer, provider]
      end

    end
  end
end
