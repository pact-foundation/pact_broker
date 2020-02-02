require 'pact_broker/pacts/selector'

module PactBroker
  module Pacts
    class Selectors < Array
      def initialize selectors = []
        super(selectors)
      end

      def self.create_for_all_of_each_tag(tag_names)
        Selectors.new(tag_names.collect{ | tag_name | Selector.all_for_tag(tag_name) })
      end

      def self.create_for_latest_of_each_tag(tag_names)
        Selectors.new(tag_names.collect{ | tag_name | Selector.latest_for_tag(tag_name) })
      end

      def self.create_for_overall_latest
        Selectors.new([Selector.overall_latest])
      end

      def + other
        Selectors.new(super)
      end

      # might actually be, but this code doesn't know it.
      def overall_latest?
        any?(&:overall_latest?)
      end

      def latest_for_tag?
        any?(&:latest_for_tag?)
      end

      def tag_names_for_selectors_for_latest_pacts
        select(&:latest_for_tag?).collect(&:tag)
      end
    end
  end
end
