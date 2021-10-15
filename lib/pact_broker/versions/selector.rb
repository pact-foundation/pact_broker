require "pact_broker/pacts/selector"
require "pact_broker/hash_refinements"

module PactBroker
  module Versions
    class Selector < PactBroker::Pacts::Selector
      def resolve_for_branch(consumer_version, resolved_branch_name)
        # Need to rename branch to branch_name
        ResolvedSelector.new(self.to_h.merge({ resolved_branch_name: resolved_branch_name }.compact), consumer_version)
      end
    end

    class ResolvedSelector < PactBroker::Pacts::ResolvedSelector
      using PactBroker::HashRefinements

      PROPERTY_NAMES = PactBroker::Pacts::Selector::PROPERTY_NAMES + [:version, :resolved_branch_name]

      def initialize(properties = {}, version)
        properties.without(*PROPERTY_NAMES).tap { |it| warn("WARN: Unsupported property for #{self.class.name}: #{it.keys.join(", ")} at #{caller[0..3]}") if it.any? }
        merge!(properties.merge(version: version))
      end

      def resolved_branch_name
        self[:resolved_branch_name]
      end

      def version
        self[:version]
      end
    end
  end
end
