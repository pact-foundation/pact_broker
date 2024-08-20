require "pact_broker/api/contracts/base_contract"

module PactBroker
  module Api
    module Contracts
      class ConsumerVersionSelectorContract < BaseContract
        option :parent # the parent hash in which the ConsumerVersionSelector is embedded

        BRANCH_KEYS = [:latest, :tag, :fallbackTag, :branch, :fallbackBranch, :matchingBranch, :mainBranch]
        ENVIRONMENT_KEYS = [:environment, :deployed, :released, :deployedOrReleased]
        ALL_KEYS = BRANCH_KEYS + ENVIRONMENT_KEYS + [:consumer]

        json do
          optional(:mainBranch).filled(included_in?: [true])
          optional(:tag).filled(:str?)
          optional(:branch).filled { str? | eql?(true) }
          optional(:matchingBranch).filled(included_in?: [true])
          optional(:latest).filled(included_in?: [true, false])
          optional(:fallbackTag).filled(:str?)
          optional(:fallbackBranch).filled(:str?)
          optional(:consumer).filled(:str?)
          optional(:deployed).filled(included_in?: [true])
          optional(:released).filled(included_in?: [true])
          optional(:deployedOrReleased).filled(included_in?: [true])
          optional(:environment).filled(:str?)
        end

        rule(:consumer).validate(:not_blank_if_present)

        # has minimum required params
        rule(*ALL_KEYS) do
          if not_provided?(values[:mainBranch]) &&
              not_provided?(values[:tag]) &&
              not_provided?(values[:branch]) &&
              not_provided?(values[:environment]) &&
              values[:matchingBranch] != true &&
              values[:deployed] != true &&
              values[:released] != true &&
              values[:deployedOrReleased] != true &&
              values[:latest] != true

            base.failure(validation_message("pacts_for_verification_selector_required_params_missing"))
          end
        end

        # mainBranch
        rule(*ALL_KEYS) do
          if values[:mainBranch] && values.slice(*ALL_KEYS - [:consumer, :mainBranch, :latest]).any?
            base.failure(validation_message("pacts_for_verification_selector_main_branch_with_other_param_disallowed"))
          end
        end

        # mainBranch/latest
        rule(:mainBranch, :latest) do
          if values[:mainBranch] && values[:latest] == false
            base.failure(validation_message("pacts_for_verification_selector_main_branch_and_latest_false_disallowed"))
          end
        end

        # matchingBranch
        rule(*ALL_KEYS) do
          if values[:matchingBranch] && values.slice(*ALL_KEYS - [:consumer, :matchingBranch]).any?
            base.failure(validation_message("pacts_for_verification_selector_matching_branch_with_other_param_disallowed"))
          end

          if values[:matchingBranch] && not_provided?(parent[:providerVersionBranch])
            base.failure(validation_message("pacts_for_verification_selector_matching_branch_requires_provider_version_branch"))
          end
        end

        # tag and branch
        rule(:tag, :branch) do
          if values[:tag] && values[:branch]
            base.failure(validation_message("pacts_for_verification_selector_tag_and_branch_disallowed"))
          end
        end

        # branch/environment keys
        rule(*ALL_KEYS) do
          non_environment_fields = values.slice(*BRANCH_KEYS).keys.sort
          environment_related_fields = values.slice(*ENVIRONMENT_KEYS).keys.sort

          if (non_environment_fields.any? && environment_related_fields.any?)
            base.failure("cannot specify the #{PactBroker::Messages.pluralize("field", non_environment_fields.count)} #{non_environment_fields.join("/")} with the #{PactBroker::Messages.pluralize("field", environment_related_fields.count)} #{environment_related_fields.join("/")}")
          end
        end

        # fallbackTag
        rule(:fallbackTag, :tag, :latest) do
          if values[:fallbackTag] && !values[:latest]
            base.failure(validation_message("pacts_for_verification_selector_fallback_tag"))
          end

          if values[:fallbackTag] && !values[:tag]
            base.failure(validation_message("pacts_for_verification_selector_fallback_tag_requires_tag"))
          end
        end

        # fallbackBranch
        rule(:fallbackBranch, :branch, :latest) do
          if values[:fallbackBranch] && !values[:branch]
            base.failure(validation_message("pacts_for_verification_selector_fallback_branch_requires_branch"))
          end


          if values[:fallbackBranch] && values[:latest] == false
            base.failure(validation_message("pacts_for_verification_selector_fallback_branch_and_latest_false_disallowed"))
          end
        end

        # branch/latest
        rule(:branch, :latest) do
          if values[:branch] && values[:latest] == false
            base.failure(validation_message("pacts_for_verification_selector_branch_and_latest_false_disallowed"))
          end
        end

        # environment
        rule(:environment) do
          validate_environment_with_name_exists(value, key) if provided?(value)
        end

        # deployed, released, deployedOrReleased
        rule(:deployed, :released, :deployedOrReleased) do
          if values[:deployed] && values[:released]
            base.failure(validation_message("pacts_for_verification_selector_deployed_and_released_disallowed"))
          end

          if values[:deployed] && values[:deployedOrReleased]
            base.failure(validation_message("pacts_for_verification_selector_deployed_and_deployed_or_released_disallowed"))
          end

          if values[:released] && values[:deployedOrReleased]
            base.failure(validation_message("pacts_for_verification_selector_released_and_deployed_or_released_disallowed"))
          end
        end
      end
    end
  end
end