require "dry-validation"
require "pact_broker/messages"
require "pact_broker/project_root"
require "pact_broker/string_refinements"

module PactBroker
  module Api
    module Contracts
      class CanIDeployQuerySchema < BaseContract
        using PactBroker::StringRefinements

        params do
          required(:pacticipant).filled(:string)
          required(:version).filled(:string)
          optional(:to).filled(:string)
          optional(:environment).filled(:string)
        end

        rule(:pacticipant).validate(:pacticipant_with_name_exists)
        rule(:environment).validate(:environment_with_name_exists)

        rule(:to, :environment) do
          if provided?(values[:to]) && provided?(values[:environment])
            base.failure(PactBroker::Messages.message("errors.validation.cannot_specify_tag_and_environment"))
          end

          if not_provided?(values[:to]) && not_provided?(values[:environment])
            base.failure(PactBroker::Messages.message("errors.validation.must_specify_environment_or_tag"))
          end
        end
      end
    end
  end
end
