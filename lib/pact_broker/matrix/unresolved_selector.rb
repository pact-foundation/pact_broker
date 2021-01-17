require 'pact_broker/hash_refinements'

module PactBroker
  module Matrix
    class UnresolvedSelector < Hash
      using PactBroker::HashRefinements

      def initialize(params = {})
        merge!(params)
      end

      def self.from_hash(hash)
        new(hash.symbolize_keys.snakecase_keys.slice(:pacticipant_name, :pacticipant_version_number, :latest, :tag, :branch, :max_age))
      end

      def pacticipant_name
        self[:pacticipant_name]
      end

      def pacticipant_version_number
        self[:pacticipant_version_number]
      end

      def latest?
        !!latest
      end

      def overall_latest?
        latest? && !tag && !max_age
      end

      def latest
        self[:latest]
      end

      def tag
        self[:tag]
      end

      def branch
        self[:branch]
      end

      def latest= latest
        self[:latest] = latest
      end

      def tag= tag
        self[:tag] = tag
      end

      def branch= branch
        self[:branch] = branch
      end

      def pacticipant_name= pacticipant_name
        self[:pacticipant_name] = pacticipant_name
      end

      def pacticipant_version_number= pacticipant_version_number
        self[:pacticipant_version_number] = pacticipant_version_number
      end

      def max_age= max_age
        self[:max_age] = max_age
      end

      def max_age
        self[:max_age]
      end

      def latest_for_pacticipant_and_tag?
        !!(pacticipant_name && tag && latest)
      end

      def latest_for_pacticipant_and_branch?
        !!(pacticipant_name && branch && latest)
      end
    end
  end
end
