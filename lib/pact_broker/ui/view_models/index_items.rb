require 'pact_broker/ui/view_models/index_item'

module PactBroker
  module UI
    module ViewDomain
      class IndexItems

        def initialize index_items
          @index_items = index_items.collect{ |index_item| IndexItem.new(index_item) }.sort
        end

        def each(&block)
          index_items.each(&block)
        end

        def size_label
          case index_items.size
          when 1 then "1 pact"
          else
            "#{index_items.size} pacts"
          end
        end

        private

        attr_reader :index_items
      end
    end
  end
end