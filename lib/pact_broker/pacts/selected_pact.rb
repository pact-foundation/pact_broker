require 'delegate'

module PactBroker
  module Pacts
    class SelectedPact < SimpleDelegator
      attr_reader :pact, :selectors

      def initialize(pact, selectors)
        super(pact)
        @pact = pact
        @selectors = selectors
      end

      # might actually be, but this code doesn't know it.
      def overall_latest?
        selectors.any?(&:overall_latest?)
      end

      def latest_for_tag?
        selectors.any?(&:latest_for_tag?)
      end

      def self.merge(selected_pacts)
        latest_selected_pact = selected_pacts.sort_by(&:consumer_version_order).last
        selectors = selected_pacts.collect(&:selectors).flatten.uniq
        SelectedPact.new(latest_selected_pact.pact, selectors)
      end

      def merge(other)
        if pact_version_sha != other.pact_version_sha
          raise "These two pacts do not have the same pact_version_sha. They cannot be merged. #{pact_version_sha} and #{other.pact_version_sha}"
        else
          SelectedPact.new()
        end
      end

      def tag_names_for_selectors_for_latest_pacts
        selectors.select(&:latest_for_tag?).collect(&:tag)
      end

      def consumer_version_order
        pact.consumer_version.order
      end
    end
  end
end
