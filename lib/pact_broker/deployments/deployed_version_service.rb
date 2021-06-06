require "pact_broker/deployments/deployed_version"

module PactBroker
  module Deployments
    class DeployedVersionService
      def self.next_uuid
        SecureRandom.uuid
      end

      def self.create(uuid, version, environment, target)
        record_previous_version_undeployed(version.pacticipant, environment, target)
        DeployedVersion.create(
          uuid: uuid,
          version: version,
          pacticipant_id: version.pacticipant_id,
          environment: environment,
          target: target
        )
      end

      def self.find_deployed_versions_for_version_and_environment(version, environment)
        DeployedVersion
          .for_version_and_environment(version, environment)
          .order_by_date_desc
          .all
      end

      def self.find_currently_deployed_version_for_version_and_environment_and_target(version, environment, target)
        DeployedVersion
          .currently_deployed
          .for_version_and_environment_and_target(version, environment, target)
          .single_record
      end

      def self.find_deployed_versions_for_environment(environment)
        DeployedVersion
          .for_environment(environment)
          .order_by_date_desc
          .all
      end

      def self.find_currently_deployed_versions_for_pacticipant(pacticipant)
        DeployedVersion
          .currently_deployed
          .where(pacticipant_id: pacticipant.id)
          .eager(:version)
          .eager(:environment)
          .all
      end

      def self.record_version_undeployed(deployed_version)
        deployed_version.currently_deployed_version_id.delete
        # CurrentlyDeployedVersionId.where(pacticipant_id: pacticipant.id, environment_id: environment.id, target: target).delete
        record_previous_version_undeployed(deployed_version.version.pacticipant, deployed_version.environment, deployed_version.target)
      end

      # private

      def self.record_previous_version_undeployed(pacticipant, environment, target)
        DeployedVersion.where(
          undeployed_at: nil,
          pacticipant_id: pacticipant.id,
          environment_id: environment.id,
          target: target
        ).record_undeployed
      end
    end
  end
end
