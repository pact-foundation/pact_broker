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

      def self.find_currently_supported_versions_for_environment(environment, pacticipant_name: nil, pacticipant_version_number: nil)
        query = ReleasedVersion
          .currently_supported
          .for_environment(environment)
        query = query.for_pacticipant_name(pacticipant_name) if pacticipant_name
        query = query.for_pacticipant_version_number(pacticipant_version_number) if pacticipant_version_number
        query.all
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
