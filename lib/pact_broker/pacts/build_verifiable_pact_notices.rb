require 'pact_broker/pacts/verifiable_pact_messages'

module PactBroker
  module Pacts
    class BuildVerifiablePactNotices

      def self.call(verifiable_pact, pact_url, options)
        messages = VerifiablePactMessages.new(verifiable_pact, pact_url)

        notices = [{
          when: 'before_verification',
          text: messages.inclusion_reason
        }]

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
