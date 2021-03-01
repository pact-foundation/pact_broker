require 'pact_broker/deployments/deployed_version'

module PactBroker
  module Deployments
    class DeployedVersionService
      def self.next_uuid
        SecureRandom.uuid
      end

      def self.create(uuid, version, environment, replaced_previous_deployed_version)
        if replaced_previous_deployed_version
          record_previous_version_undeployed(version.pacticipant, environment)
        end
        DeployedVersion.create(
          uuid: uuid,
          version: version,
          pacticipant_id: version.pacticipant_id,
          environment: environment,
          currently_deployed: true,
          replaced_previous_deployed_version: replaced_previous_deployed_version
        )
      end

      def self.find_deployed_versions_for_version_and_environment(version, environment)
        DeployedVersion
          .for_version_and_environment(version, environment)
          .order_by_date_desc
          .all
      end

      def self.find_deployed_versions_for_environment(environment)
        DeployedVersion
          .for_environment(environment)
          .order_by_date_desc
          .all
      end

      def self.record_previous_version_undeployed(pacticipant, environment)
        DeployedVersion.last_deployed_version(pacticipant, environment)&.record_undeployed
      end
    end
  end
end
