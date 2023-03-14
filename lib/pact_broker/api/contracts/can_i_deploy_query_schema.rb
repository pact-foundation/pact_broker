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

        rule(:environment) do
          require "pact_broker/deployments/environment_service"
          if value && !PactBroker::Deployments::EnvironmentService.find_by_name(value)
            key.failure(PactBroker::Messages.message("errors.validation.environment_not_found", value: value))
          end
        end

        rule(:to, :environment) do
          if values[:to] && values[:environment]
            base.failure(PactBroker::Messages.message("errors.validation.cannot_specify_tag_and_environment"))
          end

          if values[:to].blank? && values[:environment].blank?
            base.failure(PactBroker::Messages.message("errors.validation.must_specify_environment_or_tag"))
          end
        end
      end
    end
  end
end
