require "pact_broker/api/contracts/base_contract"

module PactBroker
  module Api
    module Contracts
      class PacticipantSchema < BaseContract
        json do
          optional(:name).filled(:string)
          optional(:displayName).maybe(:string)
          optional(:mainBranch).maybe(:string)
          optional(:repositoryUrl).maybe(:string)
          optional(:repositoryName).maybe(:string)
          optional(:repositoryNamespace).maybe(:string)
        end

        rule(:name).validate(:not_multiple_lines, :not_blank_if_present)
        rule(:displayName).validate(:not_multiple_lines, :not_blank_if_present)
        rule(:mainBranch).validate(:not_multiple_lines, :no_spaces_if_present, :not_blank_if_present)
        rule(:repositoryUrl).validate(:not_multiple_lines)
        rule(:repositoryName).validate(:not_multiple_lines)
        rule(:repositoryNamespace).validate(:not_multiple_lines)
      end
    end
  end
end
