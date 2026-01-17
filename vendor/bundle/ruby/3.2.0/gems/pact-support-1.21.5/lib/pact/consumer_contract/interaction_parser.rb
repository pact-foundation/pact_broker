require 'pact/specification_version'
require 'pact/consumer_contract/interaction_v2_parser'
require 'pact/consumer_contract/interaction_v3_parser'

module Pact
  class InteractionParser
    def self.call hash, options = {}
      pact_specification_version = options[:pact_specification_version] || Pact::SpecificationVersion::NIL_VERSION
      case pact_specification_version.major
      when nil, 0, 1, 2 then parse_v2_interaction(hash, pact_specification_version: pact_specification_version)
      else parse_v3_interaction(hash, pact_specification_version: pact_specification_version)
      end
    end

    def self.parse_v2_interaction hash, options
      InteractionV2Parser.call(hash, options)
    end

    def self.parse_v3_interaction hash, options
      InteractionV3Parser.call(hash, options)
    end
  end
end
