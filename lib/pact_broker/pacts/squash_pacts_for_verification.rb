# All of these pacts have the same underlying pact_version_sha (content)
# No point verifying them multiple times, so squash all the relevant info into one
# "verifiable pact"

module PactBroker
  module Pacts
    module SquashPactsForVerification
      def self.call(provider_version_tags, selected_pact, include_pending_status = false)
        domain_pact = selected_pact.pact

        if include_pending_status
          pending_provider_tags = []
          non_pending_provider_tags = []
          pending = nil
          if provider_version_tags.any?
            pending_provider_tags = domain_pact.select_pending_provider_version_tags(provider_version_tags)
            pending = pending_provider_tags.any?
          else
            pending = domain_pact.pending?
          end
          non_pending_provider_tags = provider_version_tags - pending_provider_tags
          VerifiablePact.new(
            domain_pact,
            selected_pact.selectors,
            pending,
            pending_provider_tags,
            non_pending_provider_tags
          )
        else
          VerifiablePact.new(
            domain_pact,
            selected_pact.selectors,
            nil,
            [],
            []
          )
        end
      end

      def squash_pacts_for_verification(*args)
        SquashPactsForVerification.call(*args)
      end
    end
  end
end
