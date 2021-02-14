require 'pact_broker/deployments/deployed_version'

module PactBroker
  module Deployments
    class DeployedVersionService
      def self.next_uuid
        SecureRandom.uuid
      end

      def self.create(uuid, version, environment)
        DeployedVersion.create(
          uuid: uuid,
          version: version,
          pacticipant_id: version.pacticipant_id,
          environment: environment,
          currently_deployed: true
        )
      end
    end
  end
end
