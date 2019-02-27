# A selector with the pacticipant id, name, version number, and version id set
module PactBroker
  module Matrix
    class ResolvedSelector < Hash
      NULL_VERSION_ID = -1

      def initialize(params)
        merge!(params)
      end

      def self.for_pacticipant(pacticipant)
        ResolvedSelector.new(
          pacticipant_id: pacticipant.id,
          pacticipant_name: pacticipant.name
        )
      end

      def self.for_pacticipant_and_version(pacticipant, version)
        ResolvedSelector.new(
          pacticipant_id: pacticipant.id,
          pacticipant_name: pacticipant.name,
          pacticipant_version_id: version.id,
          pacticipant_version_number: version.number
        )
      end

      # An ID of -1 will not match any rows, which is what we want
      def self.for_pacticipant_and_non_existing_version(pacticipant)
        ResolvedSelector.new(
          pacticipant_id: pacticipant.id,
          pacticipant_name: pacticipant.name,
          pacticipant_version_id: NULL_VERSION_ID,
          pacticipant_version_number: ""
        )
      end

      def pacticipant_id
        self[:pacticipant_id]
      end

      def pacticipant_name
        self[:pacticipant_name]
      end

      def pacticipant_version_id
        self[:pacticipant_version_id]
      end

      def pacticipant_version_number
        self[:pacticipant_version_number]
      end

      def version_not_found?
        pacticipant_version_id == NULL_VERSION_ID
      end
    end

  end
end