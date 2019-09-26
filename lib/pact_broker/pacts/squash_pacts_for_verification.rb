# All of these pacts have the same underlying pact_version_sha (content)
# No point verifying them multiple times, so squash all the relevant info into one
# "verifiable pact"

module PactBroker
  module Pacts
    module SquashPactsForVerification
      def self.call(provider_version_tags, head_pacts)
        domain_pact = head_pacts.first.pact
        pending_provider_tags = []
        pending = nil
        if provider_version_tags.any?
          pending_provider_tags = domain_pact.select_pending_provider_version_tags(provider_version_tags)
          pending = pending_provider_tags.any?
        else
          pending = domain_pact.pending?
        end

        non_pending_provider_tags = provider_version_tags - pending_provider_tags

        head_consumer_tags = head_pacts.collect(&:tag)
        overall_latest = head_consumer_tags.include?(nil)
        VerifiablePact.new(domain_pact,
          pending,
          pending_provider_tags,
          non_pending_provider_tags,
          head_consumer_tags.compact,
          overall_latest
        )
      end

      def squash_pacts_for_verification(*args)
        SquashPactsForVerification.call(*args)
      end
    end
  end
end
