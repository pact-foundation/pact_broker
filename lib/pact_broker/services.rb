module PactBroker
  module Services

    SERVICE_FACTORIES = {}

    extend self

    def register_service(name, &block)
      SERVICE_FACTORIES[name] = block
    end

    def get_service(name)
      SERVICE_FACTORIES[name].call
    end

    def index_service
      get_service(:index_service)
    end

    def pact_service
      get_service(:pact_service)
    end

    def pacticipant_service
      get_service(:pacticipant_service)
    end

    def tag_service
      get_service(:tag_service)
    end

    def label_service
      get_service(:label_service)
    end

    def group_service
      get_service(:group_service)
    end

    def webhook_service
      get_service(:webhook_service)
    end

    def version_service
      get_service(:version_service)
    end

    def verification_service
      get_service(:verification_service)
    end

    def badge_service
      get_service(:badge_service)
    end

    def matrix_service
      get_service(:matrix_service)
    end

    def certificate_service
      get_service(:certificate_service)
    end

    def integration_service
      get_service(:integration_service)
    end

    def webhook_trigger_service
      get_service(:webhook_trigger_service)
    end

    def metrics_service
      get_service(:metrics_service)
    end

    def environment_service
      get_service(:environment_service)
    end

    def deployed_version_service
      get_service(:deployed_version_service)
    end

    def released_version_service
      get_service(:released_version_service)
    end

    def contract_service
      get_service(:contract_service)
    end

    def branch_service
      get_service(:branch_service)
    end

    def provider_state_service
      get_service(:provider_state_service)
    end

    # rubocop: disable Metrics/MethodLength
    def register_default_services
      register_service(:index_service) do
        Index::Service
      end

      register_service(:metrics_service) do
        Metrics::Service
      end

      register_service(:matrix_service) do
        Matrix::Service
      end

      register_service(:pact_service) do
        Pacts::Service
      end

      register_service(:pacticipant_service) do
        Pacticipants::Service
      end

      register_service(:tag_service) do
        Tags::Service
      end

      register_service(:label_service) do
        Labels::Service
      end

      register_service(:group_service) do
        Groups::Service
      end

      register_service(:webhook_service) do
        Webhooks::Service
      end

      register_service(:version_service) do
        Versions::Service
      end

      register_service(:verification_service) do
        Verifications::Service
      end

      register_service(:badge_service) do
        Badges::Service
      end

      register_service(:certificate_service) do
        Certificates::Service
      end

      register_service(:integration_service) do
        Integrations::Service
      end

      register_service(:webhook_trigger_service) do
        Webhooks::TriggerService
      end

      register_service(:environment_service) do
        Deployments::EnvironmentService
      end

      register_service(:deployed_version_service) do
        PactBroker::Deployments::DeployedVersionService
      end

      register_service(:released_version_service) do
        PactBroker::Deployments::ReleasedVersionService
      end

      register_service(:contract_service) do
        PactBroker::Contracts::Service
      end

      register_service(:branch_service) do
        PactBroker::Versions::BranchService
      end

      register_service(:provider_state_service) do
        PactBroker::Pacts::ProviderStateService
      end
    end
    # rubocop: enable Metrics/MethodLength
  end
end

PactBroker::Services.register_default_services
