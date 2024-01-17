require "pact_broker/api/contracts/base_contract"
require "pact_broker/api/contracts/consumer_version_selector_contract"
require "pact_broker/logging"

module PactBroker
  module Api
    module Contracts
      class PactsForVerificationJsonQuerySchema < BaseContract
        json do
          optional(:providerVersionBranch).maybe(:string)
          optional(:providerVersionTags).maybe(:array?)
          optional(:consumerVersionSelectors).array(:hash)
          optional(:includePendingStatus).filled(included_in?: [true, false])
          optional(:includeWipPactsSince).filled(:date)
        end

        # The original implementation of pacts-for-verification unfortunately went out without any validation on the
        # providerVersionBranch at all (most likely unintentionally.)
        # When we added
        #   optional(:providerVersionBranch).filled(:string)
        # during the dry-validation upgrade, we discovered that some users/pact clients were requesting pacts for verification
        # with an empty string in the providerVersionBranch
        # This complicated logic tries to not break those customers as much as possible, while still raising an error
        # when the blank string is most likely a configuration error
        # (eg. when the request performs logic that uses the provider version branch)
        # It allows the providerVersionBranch to be unspecified/nil, as that most likely means the user did not
        # specify the branch at all.
        rule(:providerVersionBranch, :providerVersionTags, :includePendingStatus, :includeWipPactsSince) do
          branch = values[:providerVersionBranch]

          # a space is a clear user error - don't bother checking further
          if branch && branch.size > 0
            validate_not_blank_if_present(branch, key)
          end

          if !rule_error?
            tags = values[:providerVersionTags]
            include_pending = values[:includePendingStatus]
            wip = values[:includeWipPactsSince]

            # There are no tags, the user specified wip or pending, and they set a branch, but the branch is an empty or blank string...
            if !tags&.any? && (wip || include_pending) && branch && ValidationHelpers.blank?(branch)
              # most likely a user error - return a message
              key.failure(validation_message("pacts_for_verification_selector_provider_version_branch_empty"))
            end
          end

        end
        rule(:consumerVersionSelectors).validate(validate_each_with_contract: ConsumerVersionSelectorContract)
      end
    end
  end
end
