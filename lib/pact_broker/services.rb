module PactBroker
  module Services

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
  end
end
