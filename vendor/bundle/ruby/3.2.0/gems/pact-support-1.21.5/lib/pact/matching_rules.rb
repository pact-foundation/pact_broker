require 'pact/matching_rules/extract'
require 'pact/matching_rules/v3/extract'
require 'pact/matching_rules/merge'
require 'pact/matching_rules/v3/merge'

module Pact
  module MatchingRules

    # @api public Used by pact-mock_service
    def self.extract object_graph, options = {}
      pact_specification_version = options[:pact_specification_version] || Pact::SpecificationVersion::NIL_VERSION
      case pact_specification_version.major
      when nil, 0, 1, 2
        Extract.(object_graph)
      else
        V3::Extract.(object_graph)
      end
    end

    def self.merge object_graph, matching_rules, options = {}
      pact_specification_version = options[:pact_specification_version] || Pact::SpecificationVersion::NIL_VERSION
      case pact_specification_version.major
      when nil, 0, 1, 2
        Merge.(object_graph, matching_rules)
      else
        V3::Merge.(object_graph, matching_rules)
      end
    end
  end
end
