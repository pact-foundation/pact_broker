# A selector with the pacticipant id, name, version number, and version id set
# This is created from either specified or inferred data, based on the user's query
# eg.
# can-i-deploy --pacticipant Foo --version 1 (this is a specified selector)
#              --to prod (this is used to create inferred selectors)
module PactBroker
  module Matrix
    class ResolvedSelector < Hash

      # A version ID of -1 will not match any rows, which is what we want to ensure that
      # no matrix rows are returned for a version that does not exist.
      NULL_VERSION_ID = -1

      def initialize(params = {})
        merge!(params)
      end

      def self.for_pacticipant(pacticipant, type)
        ResolvedSelector.new(
          pacticipant_id: pacticipant.id,
          pacticipant_name: pacticipant.name,
          type: type
        )
      end

      def self.for_pacticipant_and_version(pacticipant, version, original_selector, type, one_of_many = false)
        ResolvedSelector.new(
          pacticipant_id: pacticipant.id,
          pacticipant_name: pacticipant.name,
          pacticipant_version_id: version.id,
          pacticipant_version_number: version.number,
          latest: original_selector[:latest],
          tag: original_selector[:tag],
          branch: original_selector[:branch],
          environment_name: original_selector[:environment_name],
          type: type,
          one_of_many: one_of_many
        )
      end

      def self.for_pacticipant_and_non_existing_version(pacticipant, original_selector, type)
        ResolvedSelector.new(
          pacticipant_id: pacticipant.id,
          pacticipant_name: pacticipant.name,
          pacticipant_version_id: NULL_VERSION_ID,
          pacticipant_version_number: original_selector[:pacticipant_version_number],
          latest: original_selector[:latest],
          tag: original_selector[:tag],
          branch: original_selector[:branch],
          environment_name: original_selector[:environment_name],
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

      def branch
        self[:branch]
      end

      def environment_name
        self[:environment_name]
      end

      def most_specific_criterion
        if pacticipant_version_id
          { pacticipant_version_id: pacticipant_version_id }
        else
          { pacticipant_id: pacticipant_id }
        end
      end

      def only_pacticipant_name_specified?
        pacticipant_name && !tag && !latest? && !pacticipant_version_number
      end

      def latest_tagged?
        latest? && tag
      end

      def latest_from_branch?
        latest? && branch
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

      # Did the user specify this selector in the user's query?
      def specified?
        self[:type] == :specified
      end

      # Was this selector inferred based on the user's query?
      #(ie. the integrations were calculated because only one selector was specified)
      def inferred?
        self[:type] == :inferred
      end

      def one_of_many?
        self[:one_of_many]
      end

      def description
        if latest_tagged? && pacticipant_version_number
          "the latest version of #{pacticipant_name} with tag #{tag} (#{pacticipant_version_number})"
        elsif latest_tagged?
          "the latest version of #{pacticipant_name} with tag #{tag} (no such version exists)"
        elsif latest_from_branch? && pacticipant_version_number
          "the latest version of #{pacticipant_name} from branch #{branch} (#{pacticipant_version_number})"
        elsif latest_from_branch?
          "the latest version of #{pacticipant_name} from branch #{branch} (no such version exists)"
        elsif latest? && pacticipant_version_number
          "the latest version of #{pacticipant_name} (#{pacticipant_version_number})"
        elsif latest?
          "the latest version of #{pacticipant_name} (no such version exists)"
        elsif tag && pacticipant_version_number
          "a version of #{pacticipant_name} with tag #{tag} (#{pacticipant_version_number})"
        elsif tag
          "a version of #{pacticipant_name} with tag #{tag} (no such version exists)"
        elsif environment_name && pacticipant_version_number
          prefix = one_of_many? ? "one of the versions" : "the version"
          "#{prefix} of #{pacticipant_name} currently deployed to #{environment_name} (#{pacticipant_version_number})"
        elsif environment_name
          "the version of #{pacticipant_name} currently deployed to #{environment_name} (no such version exists)"
        elsif pacticipant_version_number
          "version #{pacticipant_version_number} of #{pacticipant_name}"
        else
          "any version of #{pacticipant_name}"
        end
      end
    end
  end
end
