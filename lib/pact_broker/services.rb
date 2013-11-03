require 'pact_broker/services/pact_service'
require 'pact_broker/services/pacticipant_service'

module PactBroker
  module Services
    def pact_service
      PactService
    end

    def pacticipant_service
      PacticipantService
    end
  end
end