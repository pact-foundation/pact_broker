require "pact_broker/deployments/released_version"

module PactBroker
  module Deployments
    class ReleasedVersionService
      def self.next_uuid
        SecureRandom.uuid
      end

      def self.find_by_uuid(uuid)
        ReleasedVersion.where(uuid: uuid).single_record
      end

      def self.create(uuid, version, environment)
        ReleasedVersion.new(
          uuid: uuid,
          version: version,
          pacticipant_id: version.pacticipant_id,
          environment: environment
        ).insert_ignore
      end

      def self.find_released_version_for_version_and_environment(version, environment)
        ReleasedVersion
          .for_version_and_environment(version, environment)
          .single_record
      end

      def self.record_version_support_ended(released_version)
        released_version.record_support_ended
      end
    end
  end
end
