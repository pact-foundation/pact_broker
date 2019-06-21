module PactBroker
  module Services

    def index_service
      require 'pact_broker/index/service'
      Index::Service
    end

    def pact_service
      # TODO work out how to fix circular dependency
      require 'pact_broker/pacts/service'
      Pacts::Service
    end

    def pacticipant_service
      require 'pact_broker/pacticipants/service'
      Pacticipants::Service
    end

    def tag_service
      require 'pact_broker/tags/service'
      Tags::Service
    end

    def label_service
      require 'pact_broker/labels/service'
      Labels::Service
    end

    def group_service
      require 'pact_broker/groups/service'
      Groups::Service
    end

    def webhook_service
      require 'pact_broker/webhooks/service'
      Webhooks::Service
    end

    def version_service
      require 'pact_broker/versions/service'
      Versions::Service
    end

    def verification_service
      require 'pact_broker/verifications/service'
      Verifications::Service
    end

    def badge_service
      require 'pact_broker/badges/service'
      Badges::Service
    end

    def matrix_service
      require 'pact_broker/matrix/service'
      Matrix::Service
    end

    def certificate_service
      require 'pact_broker/certificates/service'
      Certificates::Service
    end

    def integration_service
      require 'pact_broker/integrations/service'
      Integrations::Service
    end

    def webhook_trigger_service
      require 'pact_broker/webhooks/trigger_service'
      Webhooks::TriggerService
    end

    def secret_service
      require 'pact_broker/secrets/service'
      Secrets::Service
    end
  end
end
