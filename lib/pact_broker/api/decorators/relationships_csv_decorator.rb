require 'csv'
require 'set'

module PactBroker

  module Api

    module Decorators

      class RelationshipsCsvDecorator

        def initialize pacts
          @pacts = pacts
          @index_items = pacts.collect{|pact| PactBroker::Domain::IndexItem.new(pact.consumer,pact.provider)}
        end

        def to_csv
          hash = {}
          pacticipants = @index_items.collect{|r| r.pacticipants}.flatten.uniq

          @index_items.each do | index_item |
            hash[index_item.consumer.id] ||= pacticipant_array(index_item.consumer, hash.size + 1)
            hash[index_item.provider.id] ||= pacticipant_array(index_item.provider, hash.size + 1)
            hash[index_item.consumer.id] << index_item.provider.id
          end

          max_length = hash.values.collect{|array| array.size}.max

          hash.values.each do | array |
            while array.size < max_length
              array << 0
            end
          end

          CSV.generate do |csv|
            hash.values.each do | array |
              csv << array
            end
          end

        end

        def pacticipant_array pacticipant, order
          [pacticipant.id, pacticipant.name, 1, 1, 0, order]
        end

        private

        attr_accessor :pacts

      end
    end
  end
end