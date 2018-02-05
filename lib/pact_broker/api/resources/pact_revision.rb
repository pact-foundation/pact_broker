require 'pact_broker/api/resources/latest_pact'

module PactBroker
  module Api
    module Resources

      class PactRevision < LatestPact
        def pact
          @pact ||= pact_service.find_by_consumer_version_and_revision(identifier_from_path)
        end
      end
    end
  end
end
