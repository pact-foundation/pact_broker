require 'pact_broker/pacts/verifiable_pact_messages'

module PactBroker
  module Pacts
    class BuildVerifiablePactNotices

      def self.call(verifiable_pact, pact_url, options)
        messages = VerifiablePactMessages.new(verifiable_pact, pact_url)

        notices = []

        if options[:deprecated]
          append_notice(notices, 'before_verification', 'WARNING - this version of the Pact library uses a beta version of the API which will be removed in the future. Please upgrade your Pact library. See https://docs.pact.io/pact_broker/advanced_topics/provider_verification_results/#pacts-for-verification for minimum required versions.')
        end

        append_notice(notices, 'before_verification', messages.inclusion_reason)

        if options[:include_pending_status]
          append_notice(notices, 'before_verification', messages.pending_reason)
          append_notice(notices, 'after_verification:success_true_published_false', messages.verification_success_true_published_false)
          append_notice(notices, 'after_verification:success_false_published_false', messages.verification_success_false_published_false)
          append_notice(notices, 'after_verification:success_true_published_true', messages.verification_success_true_published_true)
          append_notice(notices, 'after_verification:success_false_published_true', messages.verification_success_false_published_true)
        end
        notices
      end

      def self.append_notice notices, the_when, text
        if text
          notices << {
            when: the_when,
            text: text
          }
        end
      end
    end
  end
end
