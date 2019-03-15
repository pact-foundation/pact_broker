# A selector with the pacticipant id, name, version number, and version id set
module PactBroker
  module Matrix
    class ResolvedSelector < Hash
      NULL_VERSION_ID = -1

      def initialize(params)
        merge!(params)
      end

      def self.for_pacticipant(pacticipant, type)
        ResolvedSelector.new(
          pacticipant_id: pacticipant.id,
          pacticipant_name: pacticipant.name,
          type: type
        )
      end

      def self.for_pacticipant_and_version(pacticipant, version, original_selector, type)
        ResolvedSelector.new(
          pacticipant_id: pacticipant.id,
          pacticipant_name: pacticipant.name,
          pacticipant_version_id: version.id,
          pacticipant_version_number: version.number,
          latest: original_selector[:latest],
          tag: original_selector[:tag],
          type: type
        )
      end

      # An ID of -1 will not match any rows, which is what we want
      def self.for_pacticipant_and_non_existing_version(pacticipant, original_selector, type)
        ResolvedSelector.new(
          pacticipant_id: pacticipant.id,
          pacticipant_name: pacticipant.name,
          pacticipant_version_id: NULL_VERSION_ID,
          pacticipant_version_number: original_selector[:pacticipant_version_number],
          latest: original_selector[:latest],
          tag: original_selector[:tag],
          type: type
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

      def latest?
        self[:latest]
      end

      def tag
        self[:tag]
      end

      def latest_tagged?
        latest? && tag
      end

      def version_does_not_exist?
        !version_exists?
      end

      def latest_tagged_version_that_does_not_exist?
        version_does_not_exist? && latest_tagged?
      end

      def specified_version_that_does_not_exist?
        specified? && version_does_not_exist?
      end

      def version_exists?
        pacticipant_version_id != NULL_VERSION_ID
      end

      # Did the user specify this selector in the HTTP query?
      def specified?
        self[:type] == :specified
      end

      # Was this selector inferred based on the HTTP query?
      #(ie. the integrations were calculated because only on selector was specified)
      def inferred?
        self[:type] == :inferred
      end

      def description
        if latest_tagged? && pacticipant_version_number
          "the latest version of #{pacticipant_name} with tag #{tag} (#{pacticipant_version_number})"
        elsif latest_tagged?
          "the latest version of #{pacticipant_name} with tag #{tag} (it does not exist)"
        elsif latest? && pacticipant_version_number
          "the latest version of #{pacticipant_name} (#{pacticipant_version_number})"
        elsif latest?
          "the latest version of #{pacticipant_name} (it does not exist)"
        elsif tag && pacticipant_version_number
          "a version of #{pacticipant_name} with tag #{tag} (#{pacticipant_version_number})"
        elsif tag
          "a version of #{pacticipant_name} with tag #{tag} (it does not exist)"
        elsif pacticipant_version_number
          "version #{pacticipant_version_number} of #{pacticipant_name}"
        else
          "all versions of #{pacticipant_name}"
        end
      end

      def version_does_not_exist_description
        if version_does_not_exist?
          if tag
            "No version with tag #{tag} exists for #{pacticipant_name}"
          elsif pacticipant_version_number
            "No version with number #{pacticipant_version_number} exists for #{pacticipant_name}"
          else
            "No versions exist for #{pacticipant_name}"
          end
        else
          nil
        end
      end
    end
  end
end
