require 'pact_broker/domain/group'

=begin

=end

module PactBroker

  module Functions

    class FindPotentialDuplicatePacticipantNames

      attr_reader :new_name, :existing_names

      def initialize new_name, existing_names
        @new_name = new_name
        @existing_names = existing_names
      end

      def self.call new_name, existing_names
        new(new_name, existing_names).call
      end

      def call
        return [] if existing_names.include?(new_name)

        existing_names.select do | existing_name |
          similar?(clean(new_name), clean(existing_name))
        end
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