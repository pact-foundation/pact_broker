require "forwardable"

# An array that provides the pagination details

module PactBroker
  module Dataset
    class Page < Array
      extend Forwardable

      attr_reader :query

      PAGE_PROPERTIES = [:page_size, :page_count, :page_range, :current_page, :next_page, :prev_page, :first_page?, :last_page?, :pagination_record_count, :current_page_record_count, :current_page_record_range]

      delegate PAGE_PROPERTIES => :query

      def initialize(array, query)
        super(array)
        @query = query
      end
    end
  end
end
