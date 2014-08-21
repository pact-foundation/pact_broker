require 'pact_broker/models/group'

=begin

=end

module PactBroker

  module Functions

    class FindPotentialDuplicatePacticipantNames

      attr_reader :new_name, :existing_names

      def initialize new_name, existing_names
        @new_name = clean new_name
        @existing_names = existing_names
      end

      def self.call new_name, existing_names
        new(new_name, existing_names).call
      end

      def call
        existing_names.select{ | existing_name | similar?(new_name, clean(existing_name)) }
      end

      def similar?(new_name, existing_name)
        existing_name.include?(new_name) || new_name.include?(existing_name)
      end

      def clean name #TODO uppercase S
        name.gsub(/s\b/,'').gsub(/s([A-Z])/,'\1').gsub(/[^A-Za-z0-9]/,'').downcase
      end

    end

  end
end