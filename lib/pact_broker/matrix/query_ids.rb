# This is left over from the old way of querying the matrix, and should eventually be deleted entirely

module PactBroker
  module Matrix
    class QueryIds
      attr_reader :all_pacticipant_ids, :specified_pacticipant_ids, :pacticipant_ids, :pacticipant_version_ids

      # pacticipant_version_ids - the pacticipant version ids from the selectors where the pacticipant version id is the most specific criterion
      # pacticipant_ids - the pacticipant ids from the selectors where the pacticipant id is the most specific criterion
      # all_pacticipant_ids - the pacticipant ids from all the selectors, regardless of whether or not a pacticipant version has also been specified
      # specified_pacticipant_ids the IDs of the pacticipants that were specified in the can-i-deploy query
      def initialize(all_pacticipant_ids, specified_pacticipant_ids, pacticipant_ids, pacticipant_version_ids)
        @all_pacticipant_ids = all_pacticipant_ids
        @specified_pacticipant_ids = specified_pacticipant_ids
        @pacticipant_ids = pacticipant_ids
        @pacticipant_version_ids = pacticipant_version_ids
        @all_pacticipant_ids = all_pacticipant_ids
      end

      def self.from_selectors(selectors)
        most_specific_criteria = selectors.collect(&:most_specific_criterion)
        all_pacticipant_ids = selectors.collect(&:pacticipant_id).uniq
        specified_pacticipant_ids = selectors.select(&:specified?).collect(&:pacticipant_id).uniq
        pacticipant_version_ids = collect_ids(most_specific_criteria, :pacticipant_version_id).uniq
        pacticipant_ids = collect_ids(most_specific_criteria, :pacticipant_id).uniq
        QueryIds.new(all_pacticipant_ids, specified_pacticipant_ids, pacticipant_ids, pacticipant_version_ids)
      end

      def self.collect_ids(hashes, key)
        hashes.collect{ |s| s[key] }.flatten.compact
      end
    end
  end
end
