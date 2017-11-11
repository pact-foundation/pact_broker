module PactBroker
  module Domain
    class Group < Array

      def initialize *index_items
        self.concat index_items.flatten
      end

      def == other
        Group === other && super
      end

      def include_pacticipant? pacticipant
        any? { | index_item | index_item.include? pacticipant }
      end

    end
  end
end
