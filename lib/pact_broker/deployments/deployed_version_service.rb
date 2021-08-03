require "pact_broker/deployments/deployed_version"
require "pact_broker/repositories/scopes"

module PactBroker
  module Deployments
    class DeployedVersionService
      extend PactBroker::Repositories::Scopes

      def self.next_uuid
        SecureRandom.uuid
      end

      # Policy applied at resource level to Version
      def self.find_by_uuid(uuid)
        DeployedVersion.where(uuid: uuid).single_record
      end

      def self.find_or_create(uuid, version, environment, target)
        if (deployed_version = find_currently_deployed_version_for_version_and_environment_and_target(version, environment, target))
          deployed_version
        else
          record_previous_version_undeployed(version.pacticipant, environment, target)
          DeployedVersion.create(
            uuid: uuid,
            version: version,
            pacticipant_id: version.pacticipant_id,
            environment: environment,
            target: target
          )
        end
      end

      def self.find_deployed_versions_for_version_and_environment(version, environment)
        scope_for(DeployedVersion)
          .for_version_and_environment(version, environment)
          .order_by_date_desc
          .all
      end

      # Policy applied at resource level to Version
      def self.find_currently_deployed_version_for_version_and_environment_and_target(version, environment, target)
        DeployedVersion
          .currently_deployed
          .for_version_and_environment_and_target(version, environment, target)
          .single_record
      end

      def self.find_currently_deployed_versions_for_environment(environment, pacticipant_name: nil, target: :unspecified)
        query = scope_for(DeployedVersion)
          .currently_deployed
          .for_environment(environment)
          .order_by_date_desc

        query = query.for_pacticipant_name(pacticipant_name) if pacticipant_name
        query = query.for_target(target) if target != :unspecified
        query.all
      end

      def self.find_currently_deployed_versions_for_pacticipant(pacticipant)
        scope_for(DeployedVersion)
          .currently_deployed
          .where(pacticipant_id: pacticipant.id)
          .eager(:version)
          .eager(:environment)
          .all
      end

      def self.record_version_undeployed(deployed_version)
        deployed_version.currently_deployed_version_id&.delete
        deployed_version.record_undeployed
      end

      def self.record_previous_version_undeployed(pacticipant, environment, target)
        DeployedVersion.where(
          undeployed_at: nil,
          pacticipant_id: pacticipant.id,
          environment_id: environment.id,
          target: target
        ).record_undeployed
      end

      private_class_method :record_previous_version_undeployed
    end
  end
end
