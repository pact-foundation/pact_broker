module PactBroker
  module Index
    class Page < Array
      attr_reader :pagination_record_count

      def initialize(array, pagination_record_count)
        super(array)
        @pagination_record_count = pagination_record_count
      end
    end
  end
end
