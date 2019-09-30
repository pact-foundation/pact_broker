require 'pact_broker/api/resources/verification'

module PactBroker
  module Api
    module Resources
      class LatestVerificationForLatestPact < Verification
        private

        def pact
          @pact ||= pact_service.find_latest_pact(pact_params)
        end

        def verification
          @verification ||= pact && verification_service.find_latest_for_pact(pact)
        end
      end
    end
  end
end
