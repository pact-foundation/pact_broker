require "pact_broker/deployments/released_version"
require "pact_broker/repositories/scopes"

module PactBroker
  module Deployments
    class ReleasedVersionService
      extend PactBroker::Repositories::Scopes

      def self.next_uuid
        SecureRandom.uuid
      end

      def self.find_by_uuid(uuid)
        ReleasedVersion.where(uuid: uuid).single_record
      end

      def self.create_or_update(uuid_for_new_released_version, version, environment)
        released_version = ReleasedVersion.new(
          uuid: uuid_for_new_released_version,
          version: version,
          pacticipant_id: version.pacticipant_id,
          environment: environment
        ).insert_ignore
        # Can't reproduce it in a test, but am getting a "Attempt to update object did not result in a single row modification"
        # error when marking an existing row as supported again IRL.
        ReleasedVersion.where(id: released_version.id).set_currently_supported
        released_version.refresh
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

      def self.find_currently_supported_versions_for_pacticipant(pacticipant)
        scope_for(ReleasedVersion)
          .currently_supported
          .where(pacticipant_id: pacticipant.id)
          .eager(:version)
          .eager(:environment)
          .order(:created_at, :id)
          .all
      end
    end
  end
end
