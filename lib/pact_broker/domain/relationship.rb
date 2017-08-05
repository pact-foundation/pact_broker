require 'pact_broker/verifications/verification_status'
require 'pact_broker/webhooks/status'

module PactBroker
  module Domain
    class Relationship

      attr_reader :consumer, :provider, :latest_pact, :latest_verification, :webhooks

      def initialize consumer, provider, latest_pact = nil, latest_verification = nil, webhooks = [], webhook_executions = []
        @consumer = consumer
        @provider = provider
        @latest_pact = latest_pact
        @latest_verification = latest_verification
        @webhooks = webhooks
        @webhook_executions = webhook_executions
      end

      def self.create consumer, provider, latest_pact, latest_verification, webhooks = [], webhook_executions = []
        new consumer, provider, latest_pact, latest_verification, webhooks, webhook_executions
      end

      def eq? other
        Relationship === other && other.consumer == consumer && other.provider == provider &&
          other.latest_pact == latest_pact && other.latest_verification == latest_verification &&
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

      def any_webhooks?
        @webhooks.any?
      end

      def webhook_status
        @webhook_status ||= PactBroker::Webhooks::Status.new(@webhooks, @webhook_executions).to_sym
      end

      def last_webhook_execution_date
        @last_webhook_execution_date ||= @webhook_executions.any? ? @webhook_executions.sort.last.created_at : nil
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

      def latest_verification_provider_version
        latest_verification.provider_version
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
        "Relationship between #{consumer_name} and #{provider_name}"
      end

      def to_a
        [consumer, provider]
      end

    end
  end
end
