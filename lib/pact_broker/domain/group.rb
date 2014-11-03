require 'versionomy'

module PactBroker
  module Domain
    class Group < Array

      def initialize *relationships
        self.concat relationships.flatten
      end

      def == other
        Group === other && super
      end

      def include_pacticipant? pacticipant
        any? { | relationship | relationship.include? pacticipant }
      end

    end
  end
end