require "pact_broker/hash_refinements"

module PactBroker
  module Matrix
    class UnresolvedSelector < Hash
      using PactBroker::HashRefinements

      def initialize(params = {})
        merge!(params)
      end

      def self.from_hash(hash)
        new(hash.symbolize_keys.snakecase_keys.slice(:pacticipant_name, :pacticipant_version_number, :latest, :tag, :branch, :environment_name))
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
        latest? && !tag && !branch
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

      def environment_name
        self[:environment_name]
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

      def environment_name= environment_name
        self[:environment_name] = environment_name
      end

      def pacticipant_name= pacticipant_name
        self[:pacticipant_name] = pacticipant_name
      end

      def pacticipant_version_number= pacticipant_version_number
        self[:pacticipant_version_number] = pacticipant_version_number
      end

      # TODO delete this once docker image uses new selector class for clean
      def max_age= max_age
        self[:max_age] = max_age
      end

      def max_age
        self[:max_age]
      end

      def all_for_pacticipant?
        !!pacticipant_name && !pacticipant_version_number && !tag && !branch && !latest && !environment_name && !max_age
      end

      def latest_for_pacticipant_and_tag?
        !!(pacticipant_name && tag && latest)
      end
    end
  end
end
