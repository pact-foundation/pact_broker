require "delegate"

module PactBroker
  module Pacts
    class SelectedPact < SimpleDelegator
      attr_reader :pact, :selectors

      def initialize(pact, selectors)
        super(pact)
        @pact = pact
        @selectors = selectors
      end

      def self.merge_by_pact_version_sha(selected_pacts)
        selected_pacts
          .group_by{ |p| [p.consumer_name, p.pact_version_sha] }
          .values
          .collect do | selected_pacts_for_pact_version_id |
            SelectedPact.merge(selected_pacts_for_pact_version_id)
          end
          .sort
      end

      def self.merge_by_consumer_version_number(selected_pacts)
        selected_pacts
          .group_by{ |p| [p.consumer_name, p.consumer_version_number] }
          .values
          .collect do | selected_pacts_for_consumer_version_number |
            SelectedPact.merge(selected_pacts_for_consumer_version_number)
          end
          .sort
      end

      def self.merge(selected_pacts)
        latest_selected_pact = selected_pacts.sort_by(&:consumer_version_order).last
        selectors = selected_pacts.collect(&:selectors).reduce(&:+).sort
        SelectedPact.new(latest_selected_pact.pact, selectors)
      end

      def tag_names_of_selectors_for_latest_pacts
        selectors.tag_names_of_selectors_for_latest_pacts
      end

      def branches_of_selectors_for_latest_pacts
        selectors.branches_of_selectors_for_latest_pacts
      end

      def overall_latest?
        selectors.overall_latest?
      end

      def latest_for_tag? potential_tag = nil
        selectors.latest_for_tag?(potential_tag)
      end

      def consumer_version_order
        pact.consumer_version.order
      end

      def <=> other
        pact <=> other.pact
      end
    end
  end
end
