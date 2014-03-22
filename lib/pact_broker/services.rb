require 'pact_broker/services/pact_service'
require 'pact_broker/services/pacticipant_service'
require 'pact_broker/services/tag_service'

module PactBroker
  module Services
    def pact_service
      PactService
    end

    def pacticipant_service
      PacticipantService
    end

    def tag_service
      TagService
    end
  end
end