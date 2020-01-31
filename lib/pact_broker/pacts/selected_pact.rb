require 'delegate'

module PactBroker
  module Pacts
    class SelectedPact < SimpleDelegator
      attr_reader :selector_tag_names, :latest, :selector_tag_names

      def initialize(pact, options)
        super(pact)
        @latest = options[:latest]
        @selector_tag_names = options[:selector_tag_names] || []
      end

      # might actually be, but this code doesn't know it.
      def overall_latest?
        latest? && selector_tag_names.empty?
      end

      # for backwards compat until code is updated
      def tag
        selector_tag_names.first
      end

      def latest?
        @latest
      end

      def pact
        __getobj__()
      end
    end
  end
end
