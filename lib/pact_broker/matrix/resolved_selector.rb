require "pact_broker/hash_refinements"

# A selector with the pacticipant id, name, version number, and version id set
# This is created from either specified or inferred data, based on the user's query
# eg.
# can-i-deploy --pacticipant Foo --version 1 (this is a specified selector)
#              --to prod (this is used to create inferred selectors, one for each integrated pacticipant in that environment)
# When an UnresolvedSelector specifies multiple application versions (eg. { tag: "prod" }) then a ResolvedSelector
# is created for every Version object found for the original selector.

module PactBroker
  module Matrix
    class ResolvedSelector < Hash

      using PactBroker::HashRefinements

      # A version ID of -1 will not match any rows, which is what we want to ensure that
      # no matrix rows are returned for a version that does not exist.
      NULL_VERSION_ID = -1
      NULL_PACTICIPANT_ID = -1

      def initialize(params = {})
        merge!(params)
      end

      def self.for_pacticipant(pacticipant, original_selector, type, ignore)
        ResolvedSelector.new(
          pacticipant_id: pacticipant.id,
          pacticipant_name: pacticipant.name,
          type: type,
          ignore: ignore,
          original_selector: original_selector
        )
      end

      # This is not possible for specified selectors, as there is validation at the HTTP query level to
      # ensure that all pacticipants in the specified selectors exist.
      # It is possible for the ignore selectors however.
      def self.for_non_existing_pacticipant(original_selector, type, ignore)
        ResolvedSelector.new(
          pacticipant_id: NULL_PACTICIPANT_ID,
          pacticipant_name: original_selector[:pacticipant_name],
          type: type,
          ignore: ignore,
          original_selector: original_selector
        )
      end

      # rubocop: disable Metrics/ParameterLists
      def self.for_pacticipant_and_version(pacticipant, version, original_selector, type, ignore, one_of_many = false)
        ResolvedSelector.new(
          pacticipant_id: pacticipant.id,
          pacticipant_name: pacticipant.name,
          pacticipant_version_id: version.id,
          pacticipant_version_number: version.number,
          latest: original_selector[:latest],
          tag: original_selector[:tag],
          branch: original_selector[:branch] || (original_selector[:main_branch] ? version&.values[:branch_name] : nil),
          main_branch: original_selector[:main_branch],
          environment_name: original_selector[:environment_name],
          type: type,
          ignore: ignore,
          one_of_many: one_of_many,
          original_selector: original_selector
        )
      end
      # rubocop: enable Metrics/ParameterLists

      def self.for_pacticipant_and_non_existing_version(pacticipant, original_selector, type, ignore)
        ResolvedSelector.new(
          pacticipant_id: pacticipant.id,
          pacticipant_name: pacticipant.name,
          pacticipant_version_id: NULL_VERSION_ID,
          pacticipant_version_number: original_selector[:pacticipant_version_number],
          latest: original_selector[:latest],
          tag: original_selector[:tag],
          branch: original_selector[:branch],
          main_branch: original_selector[:main_branch],
          environment_name: original_selector[:environment_name],
          type: type,
          ignore: ignore,
          original_selector: original_selector
        )
      end

      def pacticipant_version_specified_in_original_selector?
        !!self.dig(:original_selector, :pacticipant_version_number)
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

      # @return [String] the name of the branch
      def branch
        self[:branch]
      end

      # @return [Boolean]
      def main_branch?
        self[:main_branch]
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
        !!pacticipant_name && self[:original_selector].without(:pacticipant_name).none?{ |_key, value| value }
      end

      def latest_tagged?
        latest? && tag
      end

      def latest_from_branch?
        latest? && branch
      end

      def latest_from_main_branch?
        latest? && main_branch?
      end

      def pacticipant_or_version_does_not_exist?
        pacticipant_does_not_exist? || version_does_not_exist?
      end

      def pacticipant_does_not_exist?
        self[:pacticipant_id] == NULL_PACTICIPANT_ID
      end

      def version_does_not_exist?
        !version_exists?
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

      def ignore?
        self[:ignore]
      end

      def consider?
        !ignore?
      end

      def original_selector
        self[:original_selector]
      end

      # rubocop: disable Metrics/CyclomaticComplexity, Metrics/MethodLength
      def description
        if latest_tagged? && pacticipant_version_number
          "the latest version of #{pacticipant_name} with tag #{tag} (#{pacticipant_version_number})"
        elsif latest_tagged?
          "the latest version of #{pacticipant_name} with tag #{tag} (no such version exists)"
        elsif main_branch? && pacticipant_version_number.nil?
          "a version of #{pacticipant_name} from the main branch (no such version exists)"
        elsif latest_from_main_branch? && pacticipant_version_number.nil?
          "the latest version of #{pacticipant_name} from the main branch (no such verison exists)"
        elsif latest_from_branch? && pacticipant_version_number
          "the latest version of #{pacticipant_name} from branch #{branch} (#{pacticipant_version_number})"
        elsif latest_from_branch?
          "the latest version of #{pacticipant_name} from branch #{branch} (no such version exists)"
        elsif branch && pacticipant_version_number
          prefix = one_of_many? ? "one of the versions " : "the version "
          prefix + "of #{pacticipant_name} from branch #{branch} (#{pacticipant_version_number})"
        elsif branch
          "a version of #{pacticipant_name} from branch #{branch} (no such version exists)"
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
          "#{prefix} of #{pacticipant_name} currently in #{environment_name} (#{pacticipant_version_number})"
        elsif environment_name
          "a version of #{pacticipant_name} currently in #{environment_name} (no version is currently recorded as deployed/released in this environment)"
        elsif pacticipant_version_number && version_does_not_exist?
          "version #{pacticipant_version_number} of #{pacticipant_name} (no such version exists)"
        elsif pacticipant_version_number
          "version #{pacticipant_version_number} of #{pacticipant_name}"
        elsif pacticipant_does_not_exist?
          "any version of #{pacticipant_name} (no such pacticipant exists)"
        else
          "any version of #{pacticipant_name}"
        end
      end
      # rubocop: enable Metrics/CyclomaticComplexity, Metrics/MethodLength

      def version_does_not_exist_description
        if version_does_not_exist?
          if tag
            "No version with tag #{tag} exists for #{pacticipant_name}"
          elsif branch
            "No version of #{pacticipant_name} from branch #{branch} exists"
          elsif main_branch?
            "No version of #{pacticipant_name} from the main branch exists"
          elsif environment_name
            "No version of #{pacticipant_name} is currently recorded as deployed or released in environment #{environment_name}"
          elsif pacticipant_version_number
            "No pacts or verifications have been published for version #{pacticipant_version_number} of #{pacticipant_name}"
          else
            "No pacts or verifications have been published for #{pacticipant_name}"
          end
        else
          ""
        end
      end
    end
  end
end
