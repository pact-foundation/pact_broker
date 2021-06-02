require "pact_broker/ui/view_models/index_item"

module PactBroker
  module UI
    module ViewDomain
      class IndexItems

        attr_reader :pagination_record_count

        def initialize index_items, options = {}
          # Why are we sorting twice!?
          @index_items = index_items.collect{ |index_item| IndexItem.new(index_item, options) }.sort
          # until the feature flag is turned on
          @pagination_record_count = index_items.size
          @pagination_record_count = index_items.pagination_record_count if index_items.respond_to?(:pagination_record_count)
        end

        def each(&block)
          index_items.each(&block)
        end

        def empty?
          index_items.empty?
        end

        def size
          index_items.size
        end

        private

        attr_reader :index_items
      end
    end
  end
end