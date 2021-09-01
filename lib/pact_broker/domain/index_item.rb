require "pact_broker/verifications/pseudo_branch_status"
require "pact_broker/webhooks/status"

module PactBroker
  module Domain
    class IndexItem
      attr_reader :consumer,
        :provider,
        :consumer_version,
        :latest_pact,
        :latest_verification,
        :webhooks,
        :triggered_webhooks,
        :latest_verification_latest_tags

      # rubocop:disable Metrics/ParameterLists
      def self.create(consumer, provider, consumer_version, latest_pact, latest, latest_verification, webhooks = [], triggered_webhooks = [], tags = [], latest_verification_latest_tags = [], latest_for_branch = nil)
        new(consumer, provider, consumer_version, latest_pact, latest, latest_verification, webhooks, triggered_webhooks, tags, latest_verification_latest_tags, latest_for_branch)
      end
      # rubocop:enable Metrics/ParameterLists

      # rubocop:disable Metrics/ParameterLists
      def initialize(consumer, provider, consumer_version = nil, latest_pact = nil, latest = true, latest_verification = nil, webhooks = [], triggered_webhooks = [], tags = [], latest_verification_latest_tags = [], latest_for_branch = nil)
        @consumer = consumer
        @provider = provider
        @consumer_version = consumer_version
        @latest_pact = latest_pact
        @latest = latest
        @latest_verification = latest_verification
        @webhooks = webhooks
        @triggered_webhooks = triggered_webhooks
        @tags = tags
        @latest_verification_latest_tags = latest_verification_latest_tags
        @latest_for_branch = latest_for_branch
      end
      # rubocop:enable Metrics/ParameterLists

      # rubocop: disable Metrics/CyclomaticComplexity
      def eq? other
        IndexItem === other && other.consumer == consumer && other.provider == provider &&
          other.latest_pact == latest_pact &&
          other.latest? == latest? &&
          other.latest_verification == latest_verification &&
          other.webhooks == webhooks &&
          other.latest_for_branch? == latest_for_branch?
      end
      # rubocop: enable Metrics/CyclomaticComplexity

      def == other
        eq?(other)
      end

      def consumer_name
        consumer.name
      end

      def provider_name
        provider.name
      end

      def latest?
        @latest
      end

      def consumer_version_number
        @latest_pact.consumer_version_number
      end

      def consumer_version_order
        consumer_version.order
      end

      def consumer_version_branch
        consumer_version.branch
      end

      def consumer_version_branches
        consumer_version.branch_heads.collect(&:branch_name)
      end

      def consumer_version_environment_names
        (consumer_version.current_deployed_versions.collect(&:environment).collect(&:name) + consumer_version.current_supported_released_versions.collect(&:environment).collect(&:name)).uniq
      end

      def latest_for_branch?
        @latest_for_branch
      end

      def provider_version
        @latest_verification ? @latest_verification.provider_version : nil
      end

      def provider_version_number
        @latest_verification ? @latest_verification.provider_version_number : nil
      end

      def provider_version_branch
        provider_version&.branch
      end

      def provider_version_branches
        provider_version&.branch_heads&.collect(&:branch_name) || []
      end

      def provider_version_environment_names
        if provider_version
          (provider_deployed_environment_names + provider_released_environment_names).uniq
        else
          []
        end

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

      def pseudo_branch_verification_status
        @pseudo_branch_verification_status ||= PactBroker::Verifications::PseudoBranchStatus.new(@latest_pact, @latest_verification).to_sym
      end

      def ever_verified?
        !!latest_verification
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

      # Add logic for ignoring case
      def <=> other
        comparisons = [
          compare_name_asc(consumer_name, other.consumer_name),
          compare_number_desc(consumer_version.order, other.consumer_version.order),
          compare_number_desc(latest_pact.revision_number, other.latest_pact.revision_number),
          compare_name_asc(provider_name, other.provider_name)
        ]

        comparisons.find{|c| c != 0 } || 0
      end

      def compare_name_asc name1, name2
        name1&.downcase <=> name2&.downcase
      end

      def compare_number_desc number1, number2
        if number1 && number2
          number2 <=> number1
        elsif number1
          1
        else
          -1
        end
      end

      def to_s
        "Pact between #{consumer_name} #{consumer_version_number} and #{provider_name} #{provider_version_number}"
      end

      def to_a
        [consumer, provider]
      end

      def last_activity_date
        @last_activity_date ||= [latest_pact.created_at, latest_verification ? latest_verification.execution_date : nil].compact.max
      end

      private

      def provider_deployed_environment_names
        provider_version.current_deployed_versions.collect(&:environment)&.collect(&:name)
      end

      def provider_released_environment_names
        provider_version.current_supported_released_versions.collect(&:environment)&.collect(&:name)
      end
    end
  end
end
