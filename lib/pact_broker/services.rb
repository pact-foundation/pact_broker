module PactBroker
  module Services

    FACTORIES = {}

    extend self

    def register_service(name, &block)
      FACTORIES[name] = block
    end

    def get(name)
      FACTORIES[name].call
    end

    def index_service
      get(:index_service)
    end

    def pact_service
      get(:pact_service)
    end

    def pacticipant_service
      get(:pacticipant_service)
    end

    def tag_service
      get(:tag_service)
    end

    def label_service
      get(:label_service)
    end

    def group_service
      get(:group_service)
    end

    def webhook_service
      get(:webhook_service)
    end

    def version_service
      get(:version_service)
    end

    def verification_service
      get(:verification_service)
    end

    def badge_service
      get(:badge_service)
    end

    def matrix_service
      get(:matrix_service)
    end

    def certificate_service
      get(:certificate_service)
    end

    def integration_service
      get(:integration_service)
    end

    def webhook_trigger_service
      get(:webhook_trigger_service)
    end

    def metrics_service
      get(:metrics_service)
    end

    def environment_service
      get(:environment_service)
    end

    def deployed_version_service
      get(:deployed_version_service)
    end

    def contract_service
      get(:contract_service)
    end

    def register_default_services
      register_service(:index_service) do
        require 'pact_broker/index/service'
        Index::Service
      end

      register_service(:metrics_service) do
        require 'pact_broker/metrics/service'
        Metrics::Service
      end

      register_service(:matrix_service) do
        require 'pact_broker/matrix/service'
        Matrix::Service
      end

      register_service(:pact_service) do
        require 'pact_broker/pacts/service'
        Pacts::Service
      end

      register_service(:pacticipant_service) do
        require 'pact_broker/pacticipants/service'
        Pacticipants::Service
      end

      register_service(:tag_service) do
        require 'pact_broker/tags/service'
        Tags::Service
      end

      register_service(:label_service) do
        require 'pact_broker/labels/service'
        Labels::Service
      end

      register_service(:group_service) do
        require 'pact_broker/groups/service'
        Groups::Service
      end

      register_service(:webhook_service) do
        require 'pact_broker/webhooks/service'
        Webhooks::Service
      end

      register_service(:version_service) do
        require 'pact_broker/versions/service'
        Versions::Service
      end

      register_service(:verification_service) do
        require 'pact_broker/verifications/service'
        Verifications::Service
      end

      register_service(:badge_service) do
        require 'pact_broker/badges/service'
        Badges::Service
      end

      register_service(:certificate_service) do
        require 'pact_broker/certificates/service'
        Certificates::Service
      end

      register_service(:integration_service) do
        require 'pact_broker/integrations/service'
        Integrations::Service
      end

      register_service(:webhook_trigger_service) do
        require 'pact_broker/webhooks/trigger_service'
        Webhooks::TriggerService
      end

      register_service(:environment_service) do
        require 'pact_broker/deployments/environment_service'
        Deployments::EnvironmentService
      end

      register_service(:deployed_version_service) do
        require 'pact_broker/deployments/deployed_version_service'
        PactBroker::Deployments::DeployedVersionService
      end

      register_service(:contract_service) do
        require 'pact_broker/contracts/service'
        PactBroker::Contracts::Service
      end
    end
  end
end

PactBroker::Services.register_default_services
