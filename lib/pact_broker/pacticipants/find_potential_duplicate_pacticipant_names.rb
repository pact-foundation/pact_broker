require 'pact_broker/domain/group'

module PactBroker

  module Pacticipants

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
          clean(new_name) == clean(existing_name)
        end
      end

      def clean name
        self.class.split(name).collect{|w| w.chomp('s') } - ["api", "provider", "service"]
      end

      def self.split(string)
        string.gsub(/\s/, '_')
              .gsub(/::/, '/')
              .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
              .gsub(/([a-z\d])([A-Z])/, '\1_\2')
              .tr('-', '_')
              .downcase
              .split("_")
      end

    end

  end
end