
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
        Pacticipants::Repository.new
      end

      register_repository(:version_repository) do
        Versions::Repository.new
      end

      register_repository(:pact_repository) do
        PactBroker::Pacts::Repository.new
      end

      register_repository(:tag_repository) do
        Tags::Repository.new
      end

      register_repository(:label_repository) do
        Labels::Repository.new
      end

      register_repository(:webhook_repository) do
        Webhooks::Repository.new
      end

      register_repository(:verification_repository) do
        Verifications::Repository.new
      end

      register_repository(:matrix_repository) do
        Matrix::Repository.new
      end

      register_repository(:branch_repository) do
        PactBroker::Versions::BranchRepository.new
      end

      register_repository(:branch_version_repository) do
        PactBroker::Versions::BranchVersionRepository.new
      end

      register_repository(:integration_repository) do
        PactBroker::Integrations::Repository.new
      end
      # rubocop: enable Metrics/MethodLength
    end
  end
end

PactBroker::Repositories.register_default_repositories
