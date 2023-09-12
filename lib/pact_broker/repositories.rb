require "pact_broker/domain"
require "pact_broker/pacts/repository"

module PactBroker
  module Repositories
    REPOSITORY_FACTORIES = {}

    extend self

    def register_repository(name, &block)
      REPOSITORY_FACTORIES[name] = block
    end

    def get_repository(name)
      REPOSITORY_FACTORIES[name].call
    end

    def pacticipant_repository
      get_repository(:pacticipant_repository)
    end

    def version_repository
      get_repository(:version_repository)
    end

    def pact_repository
      get_repository(:pact_repository)
    end

    def tag_repository
      get_repository(:tag_repository)
    end

    def label_repository
      get_repository(:label_repository)
    end

    def webhook_repository
      get_repository(:webhook_repository)
    end

    def verification_repository
      get_repository(:verification_repository)
    end

    def matrix_repository
      get_repository(:matrix_repository)
    end

    def branch_repository
      get_repository(:branch_repository)
    end

    def branch_version_repository
      get_repository(:branch_version_repository)
    end

    def integration_repository
      get_repository(:integration_repository)
    end

    # rubocop: disable Metrics/MethodLength
    def register_default_repositories
      register_repository(:pacticipant_repository) do
        require "pact_broker/pacticipants/repository"
        Pacticipants::Repository.new
      end

      register_repository(:version_repository) do
        require "pact_broker/versions/repository"
        Versions::Repository.new
      end

      register_repository(:pact_repository) do
        PactBroker::Pacts::Repository.new
      end

      register_repository(:tag_repository) do
        require "pact_broker/tags/repository"
        Tags::Repository.new
      end

      register_repository(:label_repository) do
        require "pact_broker/labels/repository"
        Labels::Repository.new
      end

      register_repository(:webhook_repository) do
        require "pact_broker/webhooks/repository"
        Webhooks::Repository.new
      end

      register_repository(:verification_repository) do
        require "pact_broker/verifications/repository"
        Verifications::Repository.new
      end

      register_repository(:matrix_repository) do
        require "pact_broker/matrix/repository"
        Matrix::Repository.new
      end

      register_repository(:branch_repository) do
        require "pact_broker/versions/branch_repository"
        PactBroker::Versions::BranchRepository.new
      end

      register_repository(:branch_version_repository) do
        require "pact_broker/versions/branch_version_repository"
        PactBroker::Versions::BranchVersionRepository.new
      end

      register_repository(:integration_repository) do
        require "pact_broker/integrations/repository"
        PactBroker::Integrations::Repository.new
      end
      # rubocop: enable Metrics/MethodLength
    end
  end
end

PactBroker::Repositories.register_default_repositories
