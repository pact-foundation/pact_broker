module PactBroker
  module Matrix
    class UnresolvedSelector < Hash
      def initialize(params = {})
        merge!(params)
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

      def latest
        self[:latest]
      end

      def tag
        self[:tag]
      end

      def latest= latest
        self[:latest] = latest
      end

      def tag= tag
        self[:tag] = tag
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
    end
  end
end
